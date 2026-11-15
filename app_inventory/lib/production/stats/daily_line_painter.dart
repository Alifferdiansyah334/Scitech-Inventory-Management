part of 'charts.dart';

class _DailyLinePainter extends CustomPainter {
  const _DailyLinePainter({
    required this.stats,
    required this.activeIndex,
    required this.peakIndex,
    required this.palette,
  });

  final AdminStats stats;
  final int? activeIndex;
  final int peakIndex;

  /// Colours are read from the palette; a scheme change must repaint.
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 32.0, rightPad = 10.0, topPad = 12.0, bottomPad = 28.0;
    final plotW = math.max(1.0, size.width - leftPad - rightPad);
    final plotH = math.max(1.0, size.height - topPad - bottomPad);
    final maxY = niceAxisMax(stats.busiestDay);
    final gridPaint = Paint()
      ..color = ChartColors.grid
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final val = (maxY / 4) * i;
      final y = topPad + plotH * (1 - i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + plotW, y), gridPaint);
      _drawText(
        canvas,
        val.round().toString(),
        Offset(0, y - 7),
        width: leftPad - 8,
        align: TextAlign.right,
        mono: true,
      );
    }

    final n = stats.daily.length;
    if (n == 0) return;
    double xAt(int i) => leftPad + (n <= 1 ? plotW / 2 : plotW * i / (n - 1));
    double yAt(double v) => topPad + plotH * (1 - v / maxY);

    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final idx = ((n - 1) * t / ticks).round();
      final x = xAt(idx);
      final label = dayMonth(stats.start.add(Duration(days: idx)));
      final align = [TextAlign.left, TextAlign.center, TextAlign.center, TextAlign.center, TextAlign.right][t];
      final dx = x - [0.0, 28.0, 28.0, 28.0, 56.0][t];
      _drawText(canvas, label, Offset(dx, topPad + plotH + 8), width: 56, align: align);
    }

    if (stats.dailyAverage > 0) {
      final avgY = yAt(stats.dailyAverage);
      final dashPaint = Paint()
        ..color = AppColors.muted.withValues(alpha: 0.6)
        ..strokeWidth = 1.2;
      for (var x = leftPad; x < leftPad + plotW; x += 9) {
        canvas.drawLine(Offset(x, avgY), Offset(math.min(x + 5, leftPad + plotW), avgY), dashPaint);
      }
    }

    final pts = [for (var i = 0; i < n; i++) Offset(xAt(i), yAt(stats.daily[i].toDouble()))];
    final curve = _monotoneCubicPath(pts);
    final fillPath = Path.from(curve)
      ..lineTo(pts.last.dx, topPad + plotH)
      ..lineTo(pts.first.dx, topPad + plotH)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = ChartColors.main.withValues(alpha: 0.1));

    canvas.drawPath(
      curve,
      Paint()
        ..color = ChartColors.main
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (activeIndex != null && activeIndex! >= 0 && activeIndex! < n) {
      final ax = pts[activeIndex!].dx;
      canvas.drawLine(
        Offset(ax, topPad),
        Offset(ax, topPad + plotH),
        Paint()
          ..color = ChartColors.main.withValues(alpha: 0.28)
          ..strokeWidth = 1.5,
      );
    }

    final hole = Paint()..color = AppColors.card;
    for (var i = 0; i < n; i++) {
      final isPeak = i == peakIndex && stats.daily[i] > 0;
      final isSel = i == activeIndex;
      if (!isSel && !isPeak && stats.daily[i] == 0) continue;
      final p = pts[i];
      if (isSel || isPeak) {
        canvas.drawCircle(p, isSel ? 7 : 6, Paint()..color = ChartColors.main);
        canvas.drawCircle(p, 2.8, hole);
      } else {
        canvas.drawCircle(p, 3.2, hole);
        canvas.drawCircle(
          p,
          3.2,
          Paint()
            ..color = ChartColors.main
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }
  }

  /// Fritsch–Carlson monotone cubic interpolation: smooth without ever
  /// dipping below 0 or overshooting flat segments.
  Path _monotoneCubicPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;
    final n = pts.length;
    final dx = List<double>.generate(n - 1, (i) => pts[i + 1].dx - pts[i].dx);
    final dy = List<double>.generate(n - 1, (i) => pts[i + 1].dy - pts[i].dy);
    final slopes = List<double>.generate(n - 1, (i) => dx[i] == 0 ? 0 : dy[i] / dx[i]);
    final tangents = List<double>.filled(n, 0);
    tangents[0] = slopes[0];
    tangents[n - 1] = slopes[n - 2];
    for (var i = 1; i < n - 1; i++) {
      if (slopes[i - 1] * slopes[i] <= 0) {
        tangents[i] = 0;
      } else {
        tangents[i] = (slopes[i - 1] + slopes[i]) / 2;
      }
    }
    for (var i = 0; i < n - 1; i++) {
      if (slopes[i] == 0) {
        tangents[i] = 0;
        tangents[i + 1] = 0;
      } else {
        final a = tangents[i] / slopes[i];
        final b = tangents[i + 1] / slopes[i];
        final h = math.sqrt(a * a + b * b);
        if (h > 3) {
          final t = 3 / h;
          tangents[i] = t * a * slopes[i];
          tangents[i + 1] = t * b * slopes[i];
        }
      }
    }
    for (var i = 0; i < n - 1; i++) {
      final step = dx[i] / 3;
      path.cubicTo(
        pts[i].dx + step,
        pts[i].dy + tangents[i] * step,
        pts[i + 1].dx - step,
        pts[i + 1].dy - tangents[i + 1] * step,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    return path;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    required TextAlign align,
    bool mono = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: mono ? AppFonts.mono : AppFonts.sans, fontSize: 11, color: AppColors.muted),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_DailyLinePainter old) =>
      old.stats != stats ||
      old.activeIndex != activeIndex ||
      old.peakIndex != peakIndex ||
      !identical(old.palette, palette);
}
