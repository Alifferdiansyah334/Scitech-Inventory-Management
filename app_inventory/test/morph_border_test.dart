import 'dart:math' as math;
import 'package:app_inventory/ui/morph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Corner radius the border paints in [rect], measured on its outer path:
/// along the top-left diagonal the first point inside a corner of radius r
/// is s = r·(1 − 1/√2).
double cornerOf(ShapeBorder border, Rect rect) {
  final path = border.getOuterPath(rect);
  var lo = 0.0, hi = rect.shortestSide / 2;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    path.contains(rect.topLeft + Offset(mid, mid)) ? hi = mid : lo = mid;
  }
  return hi / (1 - 1 / math.sqrt2);
}

void main() {
  const rect = Rect.fromLTWH(0, 0, 160, 52);
  const pill = MorphBorder();
  const pressed = MorphBorder(radius: 12);

  test('a full radius paints as a pill at any size', () {
    expect(cornerOf(pill, rect), closeTo(26, .6));
  });

  test('the press morph starts at the pill and ends exactly at the target', () {
    final start = ShapeBorder.lerp(pill, pressed, 0)!;
    final end = ShapeBorder.lerp(pill, pressed, 1)!;
    expect(cornerOf(start, rect), closeTo(26, .6));
    expect(cornerOf(end, rect), closeTo(12, .6));
  });

  test('the spring overshoots the target corner before settling', () {
    var smallest = double.infinity;
    for (var i = 1; i < 100; i++) {
      final t = Curves.fastOutSlowIn.transform(i / 100);
      final r = cornerOf(ShapeBorder.lerp(pill, pressed, t)!, rect);
      if (r < smallest) smallest = r;
    }
    expect(smallest, lessThan(11.5), reason: 'fast spatial spring (ζ 0.6) dips past 12');
  });

  test('without spring the morph never passes the target', () {
    const from = MorphBorder(radius: 8, spring: false);
    const to = MorphBorder(radius: 16, spring: false);
    for (var i = 0; i <= 20; i++) {
      final r = cornerOf(ShapeBorder.lerp(from, to, i / 20)!, rect);
      expect(r, inInclusiveRange(7.4, 16.6));
    }
  });
}
