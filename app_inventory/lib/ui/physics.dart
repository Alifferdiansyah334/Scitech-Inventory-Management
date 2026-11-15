import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'shapes.dart';
import 'springs.dart';

part 'physics_burst.dart';

/// Pick it up and throw it: the child follows the finger with rubber-band
/// resistance, leans toward where it is going and grows a little while held.
/// On release it springs home on a wobbly spring, carrying the fling
/// velocity. Taps still reach [onTap]. Vertical drags are left to an
/// enclosing scroll view (pan needs a larger slop than vertical drag).
class SpringDraggable extends StatefulWidget {
  const SpringDraggable({required this.child, this.onTap, this.reach = 80, super.key});
  final Widget child;
  final VoidCallback? onTap;

  /// Distance the child can be pulled at most, approached asymptotically.
  final double reach;

  @override
  State<SpringDraggable> createState() => _SpringDraggableState();
}

class _SpringDraggableState extends State<SpringDraggable> with TickerProviderStateMixin {
  late final _x = AnimationController.unbounded(vsync: this);
  late final _y = AnimationController.unbounded(vsync: this);
  late final _lift = AnimationController.unbounded(vsync: this);
  late final _all = Listenable.merge([_x, _y, _lift]);
  Offset _raw = Offset.zero;

  double _band(double v) => widget.reach * v / (widget.reach + v.abs());
  double _unband(double b) {
    final c = b.clamp(-widget.reach * .98, widget.reach * .98);
    return c * widget.reach / (widget.reach - c.abs());
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _lift.dispose();
    super.dispose();
  }

  void _start(DragStartDetails _) {
    _x.stop();
    _y.stop();
    _raw = Offset(_unband(_x.value), _unband(_y.value));
    springTo(_lift, 1, AppSprings.fastSpatial);
    HapticFeedback.selectionClick();
  }

  void _update(DragUpdateDetails d) {
    _raw += d.delta;
    _x.value = _band(_raw.dx);
    _y.value = _band(_raw.dy);
  }

  void _end(Offset velocity) {
    // The band slows the child near its reach; scale the throw to match.
    springTo(_x, 0, AppSprings.wobbly, velocity: velocity.dx * .5);
    springTo(_y, 0, AppSprings.wobbly, velocity: velocity.dy * .5);
    springTo(_lift, 0, AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) {
    final still = reducedMotion(context);
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: still ? null : _start,
      onPanUpdate: still ? null : _update,
      onPanEnd: still ? null : (d) => _end(d.velocity.pixelsPerSecond),
      onPanCancel: still ? null : () => _end(Offset.zero),
      child: AnimatedBuilder(
        animation: _all,
        builder: (context, child) => Transform.translate(
          offset: Offset(_x.value, _y.value),
          child: Transform.rotate(
            angle: _x.value * .004,
            child: Transform.scale(scale: 1 + .1 * _lift.value, child: child),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Leans in 3D toward the finger while pressed, like pushing on a card, and
/// wobbles flat when let go. Uses a [Listener], so it never takes gestures
/// from its children or from scrolling; a vertical move releases the tilt.
class TiltOnTouch extends StatefulWidget {
  const TiltOnTouch({required this.child, this.maxAngle = .08, super.key});
  final Widget child;
  final double maxAngle;

  @override
  State<TiltOnTouch> createState() => _TiltOnTouchState();
}

class _TiltOnTouchState extends State<TiltOnTouch> with TickerProviderStateMixin {
  late final _rx = AnimationController.unbounded(vsync: this);
  late final _ry = AnimationController.unbounded(vsync: this);
  late final _press = AnimationController.unbounded(vsync: this);
  late final _all = Listenable.merge([_rx, _ry, _press]);
  Offset? _down;

  @override
  void dispose() {
    _rx.dispose();
    _ry.dispose();
    _press.dispose();
    super.dispose();
  }

  void _aim(Offset local) {
    final size = context.size;
    if (size == null || reducedMotion(context)) return;
    final nx = (local.dx / size.width - .5) * 2;
    final ny = (local.dy / size.height - .5) * 2;
    springTo(_ry, nx.clamp(-1, 1) * widget.maxAngle, AppSprings.fastSpatial);
    springTo(_rx, -ny.clamp(-1, 1) * widget.maxAngle, AppSprings.fastSpatial);
    springTo(_press, 1, AppSprings.fastSpatial);
  }

  void _release() {
    _down = null;
    springTo(_rx, 0, AppSprings.wobbly);
    springTo(_ry, 0, AppSprings.wobbly);
    springTo(_press, 0, AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      _down = e.localPosition;
      _aim(e.localPosition);
    },
    onPointerMove: (e) {
      final down = _down;
      if (down == null) return;
      // A mostly vertical move is the start of a scroll, not a push.
      if ((e.localPosition.dy - down.dy).abs() > 18) {
        _release();
      } else {
        _aim(e.localPosition);
      }
    },
    onPointerUp: (_) => _release(),
    onPointerCancel: (_) => _release(),
    child: AnimatedBuilder(
      animation: _all,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..rotateX(_rx.value)
          ..rotateY(_ry.value)
          ..scaleByDouble(1 - .02 * _press.value, 1 - .02 * _press.value, 1, 1),
        child: child,
      ),
      child: widget.child,
    ),
  );
}

/// Boings once when it appears: an over-damped jump in scale and a small
/// twist that wobbles out. For icons that just became selected.
class PopIn extends StatefulWidget {
  const PopIn({required this.child, super.key});
  final Widget child;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController.unbounded(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || reducedMotion(context)) return;
    _started = true;
    _c.animateWith(SpringSimulation(AppSprings.wobbly, 0, 0, 7));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.rotate(
      angle: _c.value * .12,
      child: Transform.scale(scale: 1 + _c.value * .14, child: child),
    ),
    child: widget.child,
  );
}
