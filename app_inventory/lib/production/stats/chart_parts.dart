import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'admin_stats.dart';

/// Chart series colours. Every one keeps at least 3:1 against white so a
/// segment stays visible; meaning is always repeated in a text legend.
abstract final class ChartColors {
  static const navy = AppColors.navy;
  static const blue = Color(0xFF5B7DB8);
  static const ok = AppColors.ok;
  static const waiting = AppColors.accent;
  static const bad = AppColors.bad;
  static const grid = AppColors.line;
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// "7 Nov"
String dayMonth(DateTime date) => '${date.day} ${_monthNames[date.month - 1]}';

/// White card whose title states the question the chart answers.
class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.legend,
    super.key,
  });
  final String title, subtitle;
  final Widget child;
  final Widget? trailing, legend;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        const SizedBox(height: 18),
        child,
        if (legend != null) ...[const SizedBox(height: 14), legend!],
      ],
    ),
  );
}

/// Empty chart body that says why there is nothing to draw.
class ChartEmpty extends StatelessWidget {
  const ChartEmpty(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    height: 140,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.muted),
    ),
  );
}

/// Starts charts at zero and grows them to their values after the first
/// frame with the gentle spring; reduced motion shows final values at once.
mixin ChartEntrance<T extends StatefulWidget> on State<T> {
  bool shown = false;

  Duration get chartDuration =>
      reducedMotion(context) ? Duration.zero : gentleCurve.duration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => shown = true);
    });
  }

  double grow(num value) => shown ? value.toDouble() : 0;
}

/// Horizontal ranked bars with optional asset tag and rank index.
class RankedBars extends StatefulWidget {
  const RankedBars({
    required this.rows,
    this.color = ChartColors.navy,
    super.key,
  });

  final List<({String? tagId, String label, double value, String text})> rows;
  final Color color;

  @override
  State<RankedBars> createState() => _RankedBarsState();
}

class _RankedBarsState extends State<RankedBars> with ChartEntrance {
  @override
  Widget build(BuildContext context) {
    final max = widget.rows.fold<double>(
      0,
      (a, r) => r.value > a ? r.value : a,
    );
    return Column(
      children: [
        for (final (i, row) in widget.rows.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '${i + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: i == 0 ? widget.color : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (row.tagId != null) ...[
                      AssetTag(row.tagId!, dark: i == 0),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: i == 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        row.text,
                        style: const TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      AnimatedContainer(
                        duration: chartDuration,
                        curve: gentleCurve,
                        height: 10,
                        width: max <= 0
                            ? 0
                            : box.maxWidth * grow(row.value) / max,
                        decoration: BoxDecoration(
                          color: i == 0 ? widget.color : ChartColors.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Segmented horizontal stock bars per category (available vs in-use), with
/// crisp separation and full category names that never truncate on phones.
class CategoryStockChart extends StatefulWidget {
  const CategoryStockChart({required this.stats, super.key});
  final AdminStats stats;

  @override
  State<CategoryStockChart> createState() => _CategoryStockChartState();
}

class _CategoryStockChartState extends State<CategoryStockChart>
    with ChartEntrance {
  @override
  Widget build(BuildContext context) {
    final rows = widget.stats.categories.take(6).toList();
    final maxTotal = rows.fold<int>(
      1,
      (a, r) => math.max(a, r.available + r.inUse),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${row.available} siap · ${row.inUse} dipakai',
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${row.available + row.inUse}',
                        style: const TextStyle(
                          fontFamily: AppFonts.mono,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                LayoutBuilder(
                  builder: (context, box) {
                    final availW =
                        box.maxWidth * grow(row.available) / maxTotal;
                    final usedW = box.maxWidth * grow(row.inUse) / maxTotal;
                    final gap = row.available > 0 && row.inUse > 0 ? 2.0 : 0.0;
                    return Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: chartDuration,
                            curve: gentleCurve,
                            width: math.max(0, availW - gap / 2),
                            height: 12,
                            color: ChartColors.ok,
                          ),
                          if (gap > 0) SizedBox(width: gap),
                          AnimatedContainer(
                            duration: chartDuration,
                            curve: gentleCurve,
                            width: math.max(0, usedW - gap / 2),
                            height: 12,
                            color: ChartColors.navy,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
