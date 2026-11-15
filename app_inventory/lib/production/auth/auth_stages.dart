import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../ui/button_feedback.dart';
import '../../ui/motion.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';

part 'auth_stage_equipment.dart';
part 'auth_stage_key.dart';
part 'auth_stage_envelope.dart';
part 'auth_stage_lock.dart';
part 'auth_stage_badge.dart';

/// Small star-like accent that twinkles in place.
class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.left, required this.top, required this.size, required this.t, this.phase = 0});
  final double left, top, size, t, phase;

  @override
  Widget build(BuildContext context) {
    final w = math.sin(2 * math.pi * (t + phase));
    return Positioned(
      left: left,
      top: top,
      child: Transform.scale(
        scale: .8 + .25 * w,
        child: Transform.rotate(
          angle: w * .4,
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: context.colors.secondaryContainer,
                shape: const ExpressiveShapeBorder(ExpressiveShape.sunny8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One real control per hero scene: screen readers hear a single button,
/// keyboard and focus work through InkWell, touch squashes via PressSpring
/// with a light haptic, and every activation kicks the scene on a wobbly
/// spring. Ambient drift stops under reduced motion; actions still work.
class _Scene extends StatefulWidget {
  const _Scene({
    required this.label,
    required this.hint,
    required this.builder,
    this.value,
    this.onTap,
    this.extra,
    this.period = const Duration(seconds: 6),
  });

  final String label, hint;
  final String? value;
  final VoidCallback? onTap;
  final Listenable? extra;
  final Duration period;

  /// Paints the scene at side [size] with ambient phase [t] (0..1) and the
  /// tap [kick] (springs from 0 through a few wobbles back to 0).
  final Widget Function(BuildContext context, double size, double t, double kick) builder;

  @override
  State<_Scene> createState() => _SceneState();
}

class _SceneState extends State<_Scene> with SingleTickerProviderStateMixin {
  late final _kick = AnimationController.unbounded(vsync: this);

  @override
  void dispose() {
    _kick.dispose();
    super.dispose();
  }

  void _tap() {
    widget.onTap?.call();
    if (!reducedMotion(context)) _kick.animateWith(SpringSimulation(AppSprings.wobbly, 0, 0, 9));
  }

  @override
  Widget build(BuildContext context) {
    final on = context.palette.onHero;
    return Semantics(
      button: true,
      label: widget.label,
      value: widget.value,
      hint: widget.hint,
      child: PressSpring(
        scale: .92,
        squash: .06,
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.none,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: tactileTap(_tap),
            splashColor: on.withValues(alpha: .18),
            highlightColor: on.withValues(alpha: .08),
            focusColor: on.withValues(alpha: .22),
            hoverColor: on.withValues(alpha: .06),
            child: ExcludeSemantics(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, box) => Ambient(
                    period: widget.period,
                    builder: (context, t, _) => AnimatedBuilder(
                      animation: Listenable.merge([_kick, ?widget.extra]),
                      builder: (context, _) => widget.builder(context, box.maxWidth, t, _kick.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
