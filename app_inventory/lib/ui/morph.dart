import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'springs.dart';

/// Radius meaning "fully round" (pill or circle), resolved against the
/// button's size when painted, so a pill can morph smoothly to a fixed corner.
const double fullRadius = double.infinity;

/// Inverse of [Curves.fastOutSlowIn], the curve [Material] applies to shape
/// changes. Lets a border recover linear time and apply a spring instead.
double _linearTime(double curved) {
  if (curved <= 0) return 0;
  if (curved >= 1) return 1;
  var lo = 0.0, hi = 1.0;
  for (var i = 0; i < 18; i++) {
    final mid = (lo + hi) / 2;
    if (Curves.fastOutSlowIn.transform(mid) < curved) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// Rounded-rectangle border whose corner radius morphs on a spring.
///
/// [Material] animates shape changes (pressed, selected) over the button's
/// `animationDuration` with a fixed easing curve; when both ends of that
/// animation are [MorphBorder]s the lerp re-times the change with the fast
/// spatial spring of the Material 3 Expressive motion scheme, including its
/// small overshoot. With [spring] off it lerps plainly (for widgets with very
/// short, fixed durations such as chips).
class MorphBorder extends OutlinedBorder {
  const MorphBorder({this.radius = fullRadius, this.spring = true, super.side}) : _from = null, _t = 1;

  const MorphBorder._between(this._from, this.radius, this._t, this.spring, BorderSide side) : super(side: side);

  /// Target corner radius; [fullRadius] for a pill or circle.
  final double radius;
  final bool spring;
  final MorphBorder? _from;
  final double _t;

  double _resolve(Rect rect) {
    final max = rect.shortestSide / 2;
    final target = math.min(radius, max);
    if (_from == null || _t == 1) return target;
    return lerpDouble(_from._resolve(rect), target, _t)!.clamp(0, max);
  }

  MorphBorder _towards(MorphBorder target, double curved) {
    final linear = _linearTime(curved);
    final progress = target.spring ? fastSpatialCurve.transform(linear) : linear;
    // A finished morph needs no history: drop it so interrupted presses
    // don't build long chains.
    final from = _t >= 1 && _from != null ? MorphBorder(radius: radius, spring: spring, side: side) : this;
    return MorphBorder._between(
      from,
      target.radius,
      progress,
      target.spring,
      BorderSide.lerp(side, target.side, linear),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is MorphBorder) return a._towards(this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is MorphBorder) return _towards(b, t);
    return super.lerpTo(b, t);
  }

  RRect _rrect(Rect rect) => RRect.fromRectAndRadius(rect, Radius.circular(_resolve(rect)));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRRect(_rrect(rect));

  @override
  void paintInterior(Canvas canvas, Rect rect, Paint paint, {TextDirection? textDirection}) =>
      canvas.drawRRect(_rrect(rect), paint);

  @override
  bool get preferPaintInterior => true;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final inner = _rrect(rect).inflate(side.strokeOffset / 2);
    canvas.drawRRect(inner, side.toPaint());
  }

  @override
  MorphBorder copyWith({BorderSide? side}) => _from == null
      ? MorphBorder(radius: radius, spring: spring, side: side ?? this.side)
      : MorphBorder._between(_from, radius, _t, spring, side ?? this.side);

  @override
  ShapeBorder scale(double t) => MorphBorder(radius: radius * t, spring: spring, side: side.scale(t));

  @override
  bool operator ==(Object other) =>
      other is MorphBorder &&
      other.radius == radius &&
      other.spring == spring &&
      other.side == side &&
      other._from == _from &&
      other._t == _t;

  @override
  int get hashCode => Object.hash(radius, spring, side, _from, _t);
}

/// Button shape per state: fully round at rest, [pressed] corners while held,
/// [selected] corners for toggled buttons.
WidgetStateProperty<OutlinedBorder?> morphShape({double rest = fullRadius, double pressed = 12, double? selected}) =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return MorphBorder(radius: pressed);
      if (selected != null && states.contains(WidgetState.selected)) return MorphBorder(radius: selected);
      return MorphBorder(radius: rest);
    });

/// Chip outline that rounds further when selected.
class ChipMorphBorder extends MorphBorder implements WidgetStateOutlinedBorder {
  const ChipMorphBorder({super.side}) : super(radius: 8, spring: false);

  @override
  OutlinedBorder? resolve(Set<WidgetState> states) =>
      MorphBorder(radius: states.contains(WidgetState.selected) ? 16 : 8, spring: false, side: side);
}
