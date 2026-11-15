import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tokens.dart';

/// M3 Expressive wavy linear progress: wavy active part, a gap, a flat track
/// and a stop dot at the end. Used for time elapsed on a loan and password
/// strength.
class WavyLinearProgress extends StatelessWidget {
  const WavyLinearProgress({
    required this.value,
    this.color,
    this.trackColor,
    this.height = 12,
    this.semanticsLabel,
    super.key,
  });
  final double value;
  final Color? color, trackColor;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    value: '${(value.clamp(0, 1) * 100).round()}%',
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavyLinePainter(
          value.clamp(0, 1).toDouble(),
          color ?? AppColors.brand,
          trackColor ?? AppColors.secondary,
        ),
      ),
    ),
  );
}

class _WavyLinePainter extends CustomPainter {
  _WavyLinePainter(this.value, this.color, this.track);
  final double value;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0, amp = 3.0, wavelength = 20.0, gap = 8.0;
    final y = size.height / 2;
    final end = size.width * value;
    final active = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (end > stroke) {
      final wave = Path()..moveTo(stroke / 2, y);
      for (var x = stroke / 2; x <= end - stroke / 2; x += 1.5) {
        wave.lineTo(x, y + amp * math.sin(2 * math.pi * x / wavelength));
      }
      canvas.drawPath(wave, active);
    }
    final trackStart = value <= 0 ? stroke / 2 : end + gap;
    if (trackStart < size.width - stroke / 2) {
      canvas.drawLine(
        Offset(trackStart, y),
        Offset(size.width - stroke / 2, y),
        Paint()
          ..color = track
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(Offset(size.width - 2, y), 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavyLinePainter old) => old.value != value || old.color != color || old.track != track;
}

/// Circular counterpart, with the value in the centre (e.g. "2 dari 3").
class WavyRingProgress extends StatelessWidget {
  const WavyRingProgress({
    required this.value,
    required this.child,
    this.size = 88,
    this.strokeWidth = 7,
    this.color,
    this.trackColor,
    this.semanticsLabel,
    super.key,
  });
  final double value, size, strokeWidth;
  final Widget child;
  final Color? color, trackColor;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _WavyRingPainter(
          value.clamp(0, 1).toDouble(),
          strokeWidth,
          color ?? AppColors.brand,
          trackColor ?? AppColors.highest,
        ),
        child: Center(child: child),
      ),
    ),
  );
}

class _WavyRingPainter extends CustomPainter {
  _WavyRingPainter(this.value, this.stroke, this.color, this.track);
  final double value, stroke;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke / 2 - 2;
    final waves = (2 * math.pi * r / 18).roundToDouble();
    final amp = stroke * .22;
    final end = 2 * math.pi * value;
    const gap = .24;
    final paint = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (value < 1) {
      final start = value <= 0 ? 0.0 : end + gap;
      final sweep = 2 * math.pi - start - (value <= 0 ? 0 : gap);
      if (sweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          start - math.pi / 2,
          sweep,
          false,
          paint..color = track,
        );
      }
    }
    if (value > 0) {
      final path = Path();
      const n = 220;
      for (var i = 0; i <= n; i++) {
        final t = end * i / n;
        final rr = r + amp * math.sin(waves * t);
        final p = center + Offset(rr * math.cos(t - math.pi / 2), rr * math.sin(t - math.pi / 2));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_WavyRingPainter old) => old.value != value || old.color != color || old.track != track;
}
