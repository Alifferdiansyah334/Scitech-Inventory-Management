import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'springs.dart';
import 'tokens.dart';

part 'shapes_widgets.dart';

/// Shapes from the Material 3 Expressive shape library, generated as polar
/// outlines so they scale to any size.
enum ExpressiveShape { circle, cookie9, cookie12, clover4, sunny8, burst, softBurst, flower8, pentagon, gem, arch }

/// Outline of [kind] in [rect]. [morphTo] and [morph] (0..1, may overshoot)
/// blend the outline toward another polar shape; [rotation] turns it (radians).
/// The arch is not polar: it only rotates.
Path expressiveShapePath(
  ExpressiveShape kind,
  Rect rect, {
  ExpressiveShape morphTo = ExpressiveShape.circle,
  double morph = 0,
  double rotation = 0,
}) {
  final cx = rect.center.dx, cy = rect.center.dy;
  final r = math.min(rect.width, rect.height) / 2;
  if (kind == ExpressiveShape.circle && (morph == 0 || morphTo == ExpressiveShape.circle)) {
    return Path()..addOval(Rect.fromCircle(center: rect.center, radius: r));
  }
  if (kind == ExpressiveShape.arch) {
    final corner = r * .28;
    final arch = Path()
      ..moveTo(cx - r, cy)
      ..arcToPoint(Offset(cx + r, cy), radius: Radius.circular(r))
      ..lineTo(cx + r, cy + r - corner)
      ..arcToPoint(Offset(cx + r - corner, cy + r), radius: Radius.circular(corner))
      ..lineTo(cx - r + corner, cy + r)
      ..arcToPoint(Offset(cx - r, cy + r - corner), radius: Radius.circular(corner))
      ..close();
    if (rotation == 0) return arch;
    final m = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..rotateZ(rotation)
      ..translateByDouble(-cx, -cy, 0, 1);
    return arch.transform(m.storage);
  }
  final target = morphTo == ExpressiveShape.arch ? ExpressiveShape.circle : morphTo;
  // Radii and unit directions are precomputed per shape, so a frame of a
  // morphing or spinning shape costs two trig calls instead of ~700, and the
  // outline goes to the engine as one polygon instead of 180 path calls.
  final from = _radii(kind), to = _radii(target);
  final cr = math.cos(rotation), sr = math.sin(rotation);
  final points = List<Offset>.generate(_steps, (i) {
    final k = from[i];
    final radius = r * (morph == 0 ? k : k + (to[i] - k) * morph);
    final c = _unitCos[i], s = _unitSin[i];
    return Offset(cx + radius * (c * cr - s * sr), cy + radius * (s * cr + c * sr));
  }, growable: false);
  return Path()..addPolygon(points, true);
}

const _steps = 180;

/// Directions of the outline samples, starting at 12 o'clock.
final _unitCos = Float64List.fromList([
  for (var i = 0; i < _steps; i++) math.cos(2 * math.pi * i / _steps - math.pi / 2),
]);
final _unitSin = Float64List.fromList([
  for (var i = 0; i < _steps; i++) math.sin(2 * math.pi * i / _steps - math.pi / 2),
]);
final _radiusTables = <ExpressiveShape, Float64List>{};

/// Relative radius of [kind] at every sample, computed once per shape.
Float64List _radii(ExpressiveShape kind) => _radiusTables[kind] ??= Float64List.fromList([
  for (var i = 0; i < _steps; i++) _radius(kind, 2 * math.pi * i / _steps),
]);

double _radius(ExpressiveShape kind, double t) {
  switch (kind) {
    case ExpressiveShape.cookie9:
      return .93 + .07 * math.cos(9 * t);
    case ExpressiveShape.cookie12:
      return .94 + .06 * math.cos(12 * t);
    case ExpressiveShape.clover4:
      final c = math.cos(4 * t);
      return .78 + .22 * c * c * (c > 0 ? 1 : .35);
    case ExpressiveShape.sunny8:
      return .9 + .1 * math.cos(8 * t);
    case ExpressiveShape.burst:
      final c = math.cos(12 * t);
      return .84 + .16 * math.pow(c.abs(), .6) * (c > 0 ? 1 : -.2);
    case ExpressiveShape.softBurst:
      return .9 + .1 * math.cos(10 * t);
    case ExpressiveShape.flower8:
      return .82 + .18 * math.cos(4 * t).abs();
    case ExpressiveShape.pentagon:
      final seg = (t % (2 * math.pi / 5)) - math.pi / 5;
      return (.62 * math.cos(math.pi / 5) / math.cos(seg) + .38) * 1.02;
    case ExpressiveShape.gem:
      final seg = (t % (2 * math.pi / 6)) - math.pi / 6;
      return .5 * math.cos(math.pi / 6) / math.cos(seg) + .5;
    case ExpressiveShape.circle:
    case ExpressiveShape.arch:
      return 1;
  }
}

/// [ShapeBorder] for decorations, [Material] and clipping.
class ExpressiveShapeBorder extends ShapeBorder {
  const ExpressiveShapeBorder(this.kind, {this.morphTo = ExpressiveShape.circle, this.morph = 0, this.rotation = 0});
  final ExpressiveShape kind, morphTo;
  final double morph, rotation;

  Path _path(Rect rect) => expressiveShapePath(kind, rect, morphTo: morphTo, morph: morph, rotation: rotation);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveShapeBorder &&
      other.kind == kind &&
      other.morphTo == morphTo &&
      other.morph == morph &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(kind, morphTo, morph, rotation);
}

/// Category of an inventory item by keyword: its shape, tint and icon.
({ExpressiveShape shape, CategoryTone tone, IconData icon}) categoryStyle(String category) {
  final name = category.toLowerCase();
  bool has(List<String> words) => words.any(name.contains);
  if (has(['drone'])) {
    return (shape: ExpressiveShape.clover4, tone: CategoryTone.drone, icon: Icons.flight_outlined);
  }
  if (has(['audio', 'mic', 'suara', 'sound', 'speaker'])) {
    return (shape: ExpressiveShape.sunny8, tone: CategoryTone.audio, icon: Icons.mic_none_rounded);
  }
  if (has(['proyektor', 'projector', 'presentasi', 'video', 'monitor', 'layar', 'tv'])) {
    return (shape: ExpressiveShape.arch, tone: CategoryTone.projector, icon: Icons.slideshow_outlined);
  }
  if (has(['alat', 'tool', 'perkakas', 'kabel', 'cable', 'adaptor', 'charger', 'jaringan', 'router'])) {
    return (shape: ExpressiveShape.pentagon, tone: CategoryTone.tools, icon: Icons.handyman_outlined);
  }
  if (has(['tripod', 'stand'])) {
    return (shape: ExpressiveShape.cookie9, tone: CategoryTone.camera, icon: Icons.camera_outdoor_outlined);
  }
  if (has(['laptop', 'komputer', 'computer', 'elektronik', 'gadget'])) {
    return (shape: ExpressiveShape.gem, tone: CategoryTone.projector, icon: Icons.laptop_outlined);
  }
  if (has(['kamera', 'camera', 'foto', 'lensa'])) {
    return (shape: ExpressiveShape.cookie9, tone: CategoryTone.camera, icon: Icons.photo_camera_outlined);
  }
  return (shape: ExpressiveShape.softBurst, tone: CategoryTone.tools, icon: Icons.inventory_2_outlined);
}
