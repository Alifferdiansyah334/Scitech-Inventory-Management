import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'admin_stats.dart';
import 'chart_parts.dart';

/// Axis maximum split into four whole, readable steps (1/2/5 × 10^n).
double niceAxisMax(int value) {
  if (value <= 4) return 4;
  final raw = value / 4;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final step = [1, 2, 5, 10].map((m) => m * mag).firstWhere((s) => s >= raw);
  return step * 4;
}

/// Interactive monotone-cubic area chart with peak marker, average line, and
/// touch/hover scrubbing.
class DailyLoansChart extends StatefulWidget {
  const DailyLoansChart({required this.stats, super.key});
  final AdminStats stats;

  @override
  State<DailyLoansChart> createState() => _DailyLoansChartState();
}

class _DailyLoansChartState extends State<DailyLoansChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
  );
  bool _started = false;
  int? _active;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reducedMotion(context)) _progress.value = 1;
    if (!reducedMotion(context)) springTo(_progress, 1, AppSprings.gentle);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _pickAt(double dx, double width) {
    const leftPad = 32.0, rightPad = 10.0;
    final plotW = math.max(1.0, width - leftPad - rightPad);
    final n = widget.stats.days;
    if (n <= 1) return;
    final ratio = ((dx - leftPad) / plotW).clamp(0.0, 1.0);
    final idx = (ratio * (n - 1)).round();
    if (_active != idx) setState(() => _active = idx);
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final peakIdx = stats.busiestDayIndex;
    final focusIdx = _active ?? peakIdx;
    final focusDate = stats.start.add(Duration(days: focusIdx));
    final focusCount = stats.daily[focusIdx];
    final avg = stats.dailyAverage.toStringAsFixed(1).replaceAll('.', ',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _active != null
                          ? AppColors.navy
                          : AppColors.navySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _active != null
                          ? dayMonth(focusDate)
                          : 'Puncak · ${dayMonth(focusDate)}',
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _active != null ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$focusCount pinjaman',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Rata-rata $avg/hari',
                style: const TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: LayoutBuilder(
            builder: (context, box) => MouseRegion(
              onHover: (e) => _pickAt(e.localPosition.dx, box.maxWidth),
              onExit: (_) => setState(() => _active = null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (e) => _pickAt(e.localPosition.dx, box.maxWidth),
                onHorizontalDragUpdate: (e) =>
                    _pickAt(e.localPosition.dx, box.maxWidth),
                onHorizontalDragEnd: (_) => setState(() => _active = null),
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => CustomPaint(
                    size: Size(box.maxWidth, 210),
                    painter: _DailyLinePainter(
                      stats: stats,
                      progress: _progress.value.clamp(0.0, 1.0),
                      activeIndex: _active,
                      peakIndex: peakIdx,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyLinePainter extends CustomPainter {
  const _DailyLinePainter({
    required this.stats,
    required this.progress,
    required this.activeIndex,
    required this.peakIndex,
  });

  final AdminStats stats;
  final double progress;
  final int? activeIndex;
  final int peakIndex;

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
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + plotW, y),
        gridPaint,
      );
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
    double yAt(double v) => topPad + plotH * (1 - (v * progress) / maxY);

    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final idx = ((n - 1) * t / ticks).round();
      final x = xAt(idx);
      final label = dayMonth(stats.start.add(Duration(days: idx)));
      final align = [
        TextAlign.left,
        TextAlign.center,
        TextAlign.center,
        TextAlign.center,
        TextAlign.right,
      ][t];
      final dx = x - [0.0, 28.0, 28.0, 28.0, 56.0][t];
      _drawText(
        canvas,
        label,
        Offset(dx, topPad + plotH + 8),
        width: 56,
        align: align,
      );
    }

    if (stats.dailyAverage > 0) {
      final avgY = yAt(stats.dailyAverage);
      final dashPaint = Paint()
        ..color = ChartColors.blue.withValues(alpha: 0.55)
        ..strokeWidth = 1.2;
      for (var x = leftPad; x < leftPad + plotW; x += 9) {
        canvas.drawLine(
          Offset(x, avgY),
          Offset(math.min(x + 5, leftPad + plotW), avgY),
          dashPaint,
        );
      }
    }

    final pts = [
      for (var i = 0; i < n; i++)
        Offset(xAt(i), yAt(stats.daily[i].toDouble())),
    ];
    final curve = _monotoneCubicPath(pts);
    final fillPath = Path.from(curve)
      ..lineTo(pts.last.dx, topPad + plotH)
      ..lineTo(pts.first.dx, topPad + plotH)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ChartColors.navy.withValues(alpha: 0.20),
            ChartColors.navy.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(leftPad, topPad, plotW, plotH)),
    );

    canvas.drawPath(
      curve,
      Paint()
        ..color = ChartColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (activeIndex != null && activeIndex! >= 0 && activeIndex! < n) {
      final ax = pts[activeIndex!].dx;
      canvas.drawLine(
        Offset(ax, topPad),
        Offset(ax, topPad + plotH),
        Paint()
          ..color = ChartColors.navy.withValues(alpha: 0.28)
          ..strokeWidth = 1.5,
      );
    }

    for (var i = 0; i < n; i++) {
      final isPeak = i == peakIndex && stats.daily[i] > 0;
      final isSel = i == activeIndex;
      if (!isSel && !isPeak && stats.daily[i] == 0) continue;
      final p = pts[i];
      if (isSel || isPeak) {
        canvas.drawCircle(
          p,
          isSel ? 6.5 : 5.5,
          Paint()..color = isSel ? ChartColors.waiting : ChartColors.navy,
        );
        canvas.drawCircle(p, 2.6, Paint()..color = Colors.white);
      } else {
        canvas.drawCircle(p, 3.2, Paint()..color = Colors.white);
        canvas.drawCircle(
          p,
          3.2,
          Paint()
            ..color = ChartColors.navy
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
    final slopes = List<double>.generate(
      n - 1,
      (i) => dx[i] == 0 ? 0 : dy[i] / dx[i],
    );
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
        style: TextStyle(
          fontFamily: mono ? AppFonts.mono : AppFonts.sans,
          fontSize: 11,
          color: AppColors.muted,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_DailyLinePainter old) =>
      old.stats != stats ||
      old.progress != progress ||
      old.activeIndex != activeIndex ||
      old.peakIndex != peakIndex;
}
