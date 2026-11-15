import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Material 3 Expressive motion scheme (mass 1). Spatial springs move, resize
/// and morph and may overshoot slightly; effects springs recolour and fade
/// and never overshoot. Damping = 2 * ratio * sqrt(stiffness).
abstract final class AppSprings {
  static const fastSpatial = SpringDescription(mass: 1, stiffness: 800, damping: 33.94);
  static const defaultSpatial = SpringDescription(mass: 1, stiffness: 380, damping: 31.19);
  static const slowSpatial = SpringDescription(mass: 1, stiffness: 200, damping: 22.63);
  static const fastEffects = SpringDescription(mass: 1, stiffness: 3800, damping: 123.29);
  static const defaultEffects = SpringDescription(mass: 1, stiffness: 1600, damping: 80);
  static const slowEffects = SpringDescription(mass: 1, stiffness: 800, damping: 56.57);

  /// Playful springs for direct manipulation (drag, squash, pop): visible
  /// overshoot and a few wobbles. Damping ratios 0.38 and 0.3.
  static const bouncy = SpringDescription(mass: 1, stiffness: 420, damping: 15.58);
  static const wobbly = SpringDescription(mass: 1, stiffness: 260, damping: 9.67);
}

bool reducedMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Animate [controller] toward [target] with a spring, keeping its velocity.
TickerFuture springTo(AnimationController controller, double target, SpringDescription spring, {double? velocity}) =>
    controller.animateWith(SpringSimulation(spring, controller.value, target, velocity ?? controller.velocity));

/// A [Curve] that follows a spring from 0 to 1, for APIs that only accept a
/// curve and a duration (routes, bottom sheets). Use [duration] with it.
class SpringCurve extends Curve {
  SpringCurve(this.spring) : _simulation = SpringSimulation(spring, 0, 1, 0), settle = _settleTime(spring);
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
  double transformInternal(double t) => t >= 1 ? 1 : _simulation.x(t * settle);
}

final fastSpatialCurve = SpringCurve(AppSprings.fastSpatial);
final defaultSpatialCurve = SpringCurve(AppSprings.defaultSpatial);
final slowSpatialCurve = SpringCurve(AppSprings.slowSpatial);
final defaultEffectsCurve = SpringCurve(AppSprings.defaultEffects);

/// Sheet open/close timing used by every modal bottom sheet.
AnimationStyle sheetAnimation(BuildContext context) => reducedMotion(context)
    ? AnimationStyle.noAnimation
    : AnimationStyle(
        curve: defaultSpatialCurve,
        duration: defaultSpatialCurve.duration,
        reverseCurve: Curves.easeInCubic,
        reverseDuration: const Duration(milliseconds: 200),
      );

/// Press feedback for any tappable child: springs down to [scale] on touch
/// and back with the fast spatial spring. Uses a [Listener], so the child
/// keeps its own tap handling, focus and semantics. Descendants read the
/// press progress (0 rest, 1 held) with [PressSpring.progressOf], e.g. to
/// morph an expressive shape.
///
/// With [squash] above 0 the child squashes like jelly while held (wider and
/// flatter) and wobbles back on the bouncy spring when released.
class PressSpring extends StatefulWidget {
  const PressSpring({required this.child, this.enabled = true, this.scale = 0.96, this.squash = 0, super.key});
  final Widget child;
  final bool enabled;
  final double scale;
  final double squash;

  /// Press progress of the nearest enclosing [PressSpring], if any.
  static Animation<double>? progressOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PressScope>()?.progress;

  @override
  State<PressSpring> createState() => _PressSpringState();
}

class _PressScope extends InheritedWidget {
  const _PressScope({required this.progress, required super.child});
  final Animation<double> progress;
  @override
  bool updateShouldNotify(_PressScope old) => old.progress != progress;
}

class _PressSpringState extends State<PressSpring> with SingleTickerProviderStateMixin {
  late final AnimationController progress = AnimationController.unbounded(vsync: this);

  void press() {
    if (!widget.enabled || reducedMotion(context)) return;
    springTo(progress, 1, AppSprings.fastSpatial);
  }

  void release() {
    if (reducedMotion(context)) {
      progress.value = 0;
      return;
    }
    springTo(progress, 0, widget.squash > 0 ? AppSprings.bouncy : AppSprings.fastSpatial);
  }

  @override
  void dispose() {
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => press(),
    onPointerUp: (_) => release(),
    onPointerCancel: (_) => release(),
    child: _PressScope(
      progress: progress,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          final p = progress.value;
          final s = 1 - p * (1 - widget.scale);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(s * (1 + p * widget.squash), s * (1 - p * widget.squash), 1),
            child: child,
          );
        },
        child: widget.child,
      ),
    ),
  );
}

/// Route transition on the default spatial spring; reduced motion shows the
/// destination immediately.
class SpringPageTransitionsBuilder extends PageTransitionsBuilder {
  const SpringPageTransitionsBuilder();

  @override
  Duration get transitionDuration => defaultSpatialCurve.duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducedMotion(context)) return child;
    final move = CurvedAnimation(parent: animation, curve: defaultSpatialCurve, reverseCurve: Curves.easeInCubic);
    final fade = CurvedAnimation(parent: animation, curve: defaultEffectsCurve, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: move,
        builder: (context, child) => Transform.translate(offset: Offset(24 * (1 - move.value), 0), child: child),
        child: child,
      ),
    );
  }
}
