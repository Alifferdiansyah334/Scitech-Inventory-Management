import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../../ui/springs.dart';

/// Spins its child like a dial: drag around the centre to turn it, let go
/// to keep it spinning down with friction; a tap gives it a turn. Still
/// under reduced motion.
class FlingSpin extends StatefulWidget {
  const FlingSpin({required this.child, super.key});
  final Widget child;

  @override
  State<FlingSpin> createState() => _FlingSpinState();
}

class _FlingSpinState extends State<FlingSpin> with SingleTickerProviderStateMixin {
  late final _angle = AnimationController.unbounded(vsync: this);
  Offset _last = Offset.zero;

  Offset get _center => (context.size ?? Size.zero).center(Offset.zero);

  double _at(Offset p) => (p - _center).direction;

  void _spin(double velocity) => _angle.animateWith(FrictionSimulation(.22, _angle.value, velocity.clamp(-28.0, 28.0)));

  @override
  void dispose() {
    _angle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reducedMotion(context);
    return GestureDetector(
      onTap: still
          ? null
          : () {
              HapticFeedback.selectionClick();
              _spin(_angle.velocity + 9);
            },
      onPanStart: still
          ? null
          : (d) {
              _angle.stop();
              _last = d.localPosition;
              HapticFeedback.selectionClick();
            },
      onPanUpdate: still
          ? null
          : (d) {
              var delta = _at(d.localPosition) - _at(_last);
              if (delta > math.pi) delta -= 2 * math.pi;
              if (delta < -math.pi) delta += 2 * math.pi;
              _angle.value += delta;
              _last = d.localPosition;
            },
      onPanEnd: still
          ? null
          : (d) {
              final r = _last - _center;
              final v = d.velocity.pixelsPerSecond;
              _spin((r.dx * v.dy - r.dy * v.dx) / math.max(r.distanceSquared, 400));
            },
      child: AnimatedBuilder(
        animation: _angle,
        builder: (context, child) => Transform.rotate(angle: _angle.value, child: child),
        child: Padding(padding: const EdgeInsets.all(12), child: widget.child),
      ),
    );
  }
}
