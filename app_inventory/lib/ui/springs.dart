import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// The three spring presets shared with the FigCraft prototype (mass 1).
abstract final class AppSprings {
  static const snappy = SpringDescription(mass: 1, stiffness: 500, damping: 30);
  static const bouncy = SpringDescription(mass: 1, stiffness: 300, damping: 16);
  static const gentle = SpringDescription(mass: 1, stiffness: 180, damping: 27);
}

bool reducedMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Animate [controller] toward [target] with a spring, keeping its velocity.
TickerFuture springTo(
  AnimationController controller,
  double target,
  SpringDescription spring, {
  double? velocity,
}) => controller.animateWith(
  SpringSimulation(
    spring,
    controller.value,
    target,
    velocity ?? controller.velocity,
  ),
);

/// A [Curve] that follows a spring from 0 to 1, for APIs that only accept a
/// curve and a duration (routes, bottom sheets). Use [duration] with it.
class SpringCurve extends Curve {
  SpringCurve(this.spring)
    : _simulation = SpringSimulation(spring, 0, 1, 0),
      settle = _settleTime(spring);
  final SpringDescription spring;
  final SpringSimulation _simulation;

  /// Seconds until the spring stays within 0.5% of its target.
  final double settle;

  Duration get duration => Duration(milliseconds: (settle * 1000).round());

  static double _settleTime(SpringDescription spring) {
    final simulation = SpringSimulation(spring, 0, 1, 0);
    var last = 0.0;
    for (var t = 0.0; t < 3; t += 0.005) {
      if ((simulation.x(t) - 1).abs() > 0.005) last = t;
    }
    return last + 0.005;
  }

  @override
  double transformInternal(double t) =>
      t >= 1 ? 1 : _simulation.x(t * settle);
}

final snappyCurve = SpringCurve(AppSprings.snappy);
final bouncyCurve = SpringCurve(AppSprings.bouncy);
final gentleCurve = SpringCurve(AppSprings.gentle);

/// Sheet open/close timing used by every modal bottom sheet.
AnimationStyle sheetAnimation(BuildContext context) => reducedMotion(context)
    ? AnimationStyle.noAnimation
    : AnimationStyle(
        curve: bouncyCurve,
        duration: bouncyCurve.duration,
        reverseCurve: Curves.easeInCubic,
        reverseDuration: const Duration(milliseconds: 220),
      );

/// Press feedback for any tappable child: shrinks to 0.96 on touch and
/// returns with the snappy spring. Uses a [Listener], so the child keeps its
/// own tap handling, focus and semantics.
class PressSpring extends StatefulWidget {
  const PressSpring({required this.child, this.enabled = true, super.key});
  final Widget child;
  final bool enabled;

  @override
  State<PressSpring> createState() => _PressSpringState();
}

class _PressSpringState extends State<PressSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  void press() {
    if (!widget.enabled || reducedMotion(context)) return;
    scale.stop();
    scale.value = 0.96;
  }

  void release() {
    if (reducedMotion(context)) {
      scale.value = 1;
      return;
    }
    springTo(scale, 1, AppSprings.snappy);
  }

  @override
  void dispose() {
    scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => press(),
    onPointerUp: (_) => release(),
    onPointerCancel: (_) => release(),
    child: ScaleTransition(scale: scale, child: widget.child),
  );
}

/// One-time entrance: rises 16 px and fades in with the gentle spring,
/// staggered 40 ms per [index] (capped at 6 items).
class SpringReveal extends StatefulWidget {
  const SpringReveal({required this.child, this.index = 0, super.key});
  final Widget child;
  final int index;

  @override
  State<SpringReveal> createState() => _SpringRevealState();
}

class _SpringRevealState extends State<SpringReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController progress = AnimationController.unbounded(
    vsync: this,
  );
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (reducedMotion(context)) {
      progress.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 6));
    Future<void>.delayed(delay, () {
      if (mounted) springTo(progress, 1, AppSprings.gentle);
    });
  }

  @override
  void dispose() {
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, child) {
      final value = progress.value;
      return Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}

/// Route transition: incoming page rises 24 px and fades with the gentle
/// spring; reduced motion shows the page immediately.
class SpringPageTransitionsBuilder extends PageTransitionsBuilder {
  const SpringPageTransitionsBuilder();

  @override
  Duration get transitionDuration => gentleCurve.duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducedMotion(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: gentleCurve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 24 * (1 - curved.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }
}
