import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'springs.dart';

part 'playground_ball.dart';

/// A little physics box: balls fall under gravity, bounce off the walls and
/// each other, roll, and can be grabbed and thrown. A tap (no drag) calls the
/// ball's [PitBall.onTap]. Every few seconds an idle pit gets a small nudge so
/// it never looks frozen.
class BallPit extends StatefulWidget {
  const BallPit({required this.balls, this.height = 150, this.shakeOnEmptyTap = false, this.shakeTrigger, super.key});
  final List<PitBall> balls;
  final double height;
  final bool shakeOnEmptyTap;
  final Listenable? shakeTrigger;

  @override
  State<BallPit> createState() => _BallPitState();
}

class _BallPitState extends State<BallPit> with SingleTickerProviderStateMixin {
  static const _gravity = 1500.0, _restitution = .62, _friction = .992;
  late final Ticker _ticker = createTicker(_tick);
  final _rnd = math.Random();
  Size _size = Size.zero;
  PitBall? _held;
  Offset _heldTarget = Offset.zero;
  Duration _last = Duration.zero;
  Timer? _nudgeTimer;
  bool _placed = false;

  void _wake() {
    _nudgeTimer?.cancel();
    if (!mounted || reducedMotion(context) || _ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _shakeAll() {
    if (_size.isEmpty) return;
    HapticFeedback.selectionClick();
    for (final b in widget.balls) {
      b._v = Offset((_rnd.nextDouble() - .5) * 440, -480 - _rnd.nextDouble() * 220);
      b._spin = (_rnd.nextDouble() - .5) * 9;
      b._squash = .16;
    }
    _wake();
  }

  @override
  void initState() {
    super.initState();
    widget.shakeTrigger?.addListener(_shakeAll);
  }

  @override
  void didUpdateWidget(BallPit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shakeTrigger != widget.shakeTrigger) {
      oldWidget.shakeTrigger?.removeListener(_shakeAll);
      widget.shakeTrigger?.addListener(_shakeAll);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reducedMotion(context) ? _ticker.stop() : _wake();
  }

  @override
  void dispose() {
    widget.shakeTrigger?.removeListener(_shakeAll);
    _nudgeTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _place(Size size) {
    if (_placed || size.isEmpty) return;
    _placed = true;
    final n = widget.balls.length;
    for (final (i, b) in widget.balls.indexed) {
      final minX = b.radius;
      final maxX = math.max(b.radius, size.width - b.radius);
      final x = (size.width * (i + .5) / n).clamp(minX, maxX).toDouble();
      final y = (b.radius + (i.isOdd ? 0 : b.radius * 1.15) + _rnd.nextDouble() * 14)
          .clamp(b.radius, math.max(b.radius, size.height - b.radius))
          .toDouble();
      b._p = Offset(x, y);
      b._v = Offset((_rnd.nextDouble() - .5) * 240, 0);
    }
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || _size.isEmpty) return;
    dt = math.min(dt, 1 / 30);
    // Two substeps keep fast throws from tunnelling through walls.
    for (var s = 0; s < 2; s++) {
      _step(dt / 2);
    }
    setState(() {});
    if (_held == null &&
        widget.balls.every(
          (b) => b._v.distance < 10 && b._spin.abs() < .15 && b._squash < .01 && b._p.dy >= _size.height - b.radius - 1,
        )) {
      _ticker.stop();
      _nudgeTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || !TickerMode.valuesOf(context).enabled) return;
        widget.balls[_rnd.nextInt(widget.balls.length)]._v = Offset((_rnd.nextDouble() - .5) * 500, -620);
        _wake();
      });
    }
  }

  void _step(double dt) {
    final w = _size.width, h = _size.height;
    for (final b in widget.balls) {
      if (b == _held) {
        final clamped = Offset(
          _heldTarget.dx.clamp(b.radius, math.max(b.radius, w - b.radius)),
          _heldTarget.dy.clamp(b.radius, math.max(b.radius, h - b.radius)),
        );
        final nv = (clamped - b._p) / dt;
        b._v = Offset.lerp(b._v, nv, .5)!;
        b._p = clamped;
      } else {
        b._v = Offset(b._v.dx * _friction, b._v.dy * _friction + _gravity * dt);
        b._p += b._v * dt;
      }
      final r = b.radius;
      if (b._p.dy > h - r) {
        b._p = Offset(b._p.dx, h - r);
        if (b._v.dy > 0) {
          if (b._v.dy > 260) b._squash = math.min(.28, b._v.dy / 3000);
          b._v = Offset(b._v.dx * .9, -b._v.dy * _restitution);
        }
        // Rolling: spin follows the ground speed.
        b._spin = b._v.dx / r;
      }
      if (b._p.dy < r) {
        b._p = Offset(b._p.dx, r);
        if (b._v.dy < 0) b._v = Offset(b._v.dx, -b._v.dy * _restitution);
      }
      if (b._p.dx < r) {
        b._p = Offset(r, b._p.dy);
        if (b._v.dx < 0) b._v = Offset(-b._v.dx * _restitution, b._v.dy);
      }
      if (b._p.dx > w - r) {
        b._p = Offset(w - r, b._p.dy);
        if (b._v.dx > 0) b._v = Offset(-b._v.dx * _restitution, b._v.dy);
      }
      b._angle += b._spin * dt;
      b._spin *= .995;
      b._squash *= math.pow(.0005, dt).toDouble();
    }
    // Ball-ball collisions, equal mass.
    final balls = widget.balls;
    for (var i = 0; i < balls.length; i++) {
      for (var j = i + 1; j < balls.length; j++) {
        final a = balls[i], b = balls[j];
        final d = b._p - a._p;
        final dist = d.distance, min = a.radius + b.radius;
        if (dist == 0 || dist >= min) continue;
        final n = d / dist;
        final push = n * ((min - dist) / 2);
        if (a != _held) a._p -= push;
        if (b != _held) b._p += push;
        final rel = (b._v - a._v).dx * n.dx + (b._v - a._v).dy * n.dy;
        if (rel < 0) {
          final imp = n * (-(1 + _restitution) * rel / 2);
          if (a != _held) a._v -= imp;
          if (b != _held) b._v += imp;
          a._spin -= rel / a.radius * .3;
          b._spin += rel / b.radius * .3;
        }
      }
    }
  }

  PitBall? _hit(Offset p) {
    for (final b in widget.balls.reversed) {
      if ((p - b._p).distance <= b.radius + 6) return b;
    }
    return null;
  }

  bool _canGrabGlobal(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return _hit(box.globalToLocal(globalPosition)) != null;
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LayoutBuilder(
      builder: (context, box) {
        _size = Size(box.maxWidth, widget.height);
        _place(_size);
        return RawGestureDetector(
          gestures: {
            TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (instance) {
                instance.onTapUp = (d) {
                  final b = _hit(d.localPosition);
                  if (b == null) {
                    if (widget.shakeOnEmptyTap) _shakeAll();
                    return;
                  }
                  b._v += const Offset(0, -500);
                  b._squash = .2;
                  _wake();
                  b.onTap?.call();
                };
              },
            ),
            _BallPanRecognizer: GestureRecognizerFactoryWithHandlers<_BallPanRecognizer>(
              () => _BallPanRecognizer(canGrab: _canGrabGlobal),
              (instance) {
                instance
                  ..canGrab = _canGrabGlobal
                  ..onStart = (d) {
                    final b = _hit(d.localPosition);
                    if (b == null) return;
                    HapticFeedback.selectionClick();
                    _held = b;
                    _heldTarget = b._p;
                    _wake();
                  }
                  ..onUpdate = (d) {
                    _heldTarget += d.delta;
                  }
                  ..onEnd = (d) {
                    final b = _held;
                    _held = null;
                    if (b == null) return;
                    final v = d.velocity.pixelsPerSecond;
                    b._v = v.distance > 2600 ? v / v.distance * 2600 : v;
                    b._spin = b._v.dx / b.radius;
                  }
                  ..onCancel = () => _held = null;
              },
            ),
          },
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final b in widget.balls)
                  Positioned(
                    left: b._p.dx - b.radius,
                    top: b._p.dy - b.radius,
                    child: Semantics(
                      button: b.onTap != null,
                      label: b.label,
                      onTap: b.onTap,
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: Matrix4.diagonal3Values(1 + b._squash, 1 - b._squash, 1),
                        child: Transform.rotate(
                          angle: b._angle,
                          child: Transform.scale(
                            scale: b == _held ? 1.12 : 1,
                            child: SizedBox.square(dimension: b.radius * 2, child: b.child),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
