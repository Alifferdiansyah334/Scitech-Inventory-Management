import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'admin_stats.dart';
import 'chart_parts.dart';

part 'daily_line_painter.dart';

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

class _DailyLoansChartState extends State<DailyLoansChart> {
  int? _active;

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
        Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _active != null ? AppColors.brand : AppColors.fixed,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    _active != null ? dayMonth(focusDate) : 'Puncak · ${dayMonth(focusDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabular,
                      color: _active != null ? AppColors.onBrand : AppColors.onFixed,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xs + 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$focusCount',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                          fontFeatures: tabular,
                          color: AppColors.ink,
                        ),
                      ),
                      TextSpan(
                        text: ' pinjaman',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpace.lg,
              runSpacing: AppSpace.xs + 2,
              children: [
                LegendSwatch(color: ChartColors.main, label: 'Pinjaman per hari'),
                DashKey('Rata-rata $avg/hari'),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        SizedBox(
          height: 210,
          child: LayoutBuilder(
            builder: (context, box) => MouseRegion(
              onHover: (e) => _pickAt(e.localPosition.dx, box.maxWidth),
              onExit: (_) => setState(() => _active = null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (e) => _pickAt(e.localPosition.dx, box.maxWidth),
                onHorizontalDragUpdate: (e) => _pickAt(e.localPosition.dx, box.maxWidth),
                onHorizontalDragEnd: (_) => setState(() => _active = null),
                child: CustomPaint(
                  size: Size(box.maxWidth, 210),
                  painter: _DailyLinePainter(
                    stats: stats,
                    activeIndex: _active,
                    peakIndex: peakIdx,
                    palette: AppPalette.current,
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
