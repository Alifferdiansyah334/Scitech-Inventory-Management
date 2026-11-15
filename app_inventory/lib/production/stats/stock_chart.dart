import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import 'admin_stats.dart';
import 'chart_parts.dart';

/// Stock per category (available vs in use) as segments on a pill track
/// scaled to the largest category, with the category's shape and tint and
/// full names that never truncate on phones.
class CategoryStockChart extends StatelessWidget {
  const CategoryStockChart({required this.stats, super.key});
  final AdminStats stats;

  static const _barH = 12.0;

  @override
  Widget build(BuildContext context) {
    final rows = stats.categories.take(6).toList();
    final maxTotal = rows.fold<int>(1, (a, r) => math.max(a, r.available + r.inUse));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShapeIcon.category(row.name, size: 44),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(row.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${row.available} siap · ${row.inUse} dipakai · ${row.available + row.inUse} total',
                        style: TextStyle(fontSize: 12, fontFeatures: tabular, color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      _StockTrack(available: row.available, inUse: row.inUse, max: maxTotal),
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

/// Pill track the width of the largest category; available and in-use
/// segments sit inside it, joined by a small gap with tight inner corners.
class _StockTrack extends StatelessWidget {
  const _StockTrack({required this.available, required this.inUse, required this.max});
  final int available, inUse, max;

  @override
  Widget build(BuildContext context) {
    const h = CategoryStockChart._barH;
    const inner = Radius.circular(2);
    const outer = Radius.circular(h / 2);
    return Container(
      height: h,
      decoration: BoxDecoration(color: ChartColors.track, borderRadius: BorderRadius.circular(AppRadii.full)),
      child: LayoutBuilder(
        builder: (context, box) {
          final both = available > 0 && inUse > 0;
          final gap = both ? 3.0 : 0.0;
          final availW = box.maxWidth * available / max;
          final usedW = box.maxWidth * inUse / max;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (available > 0)
                Container(
                  width: math.max(0, availW - gap / 2),
                  decoration: BoxDecoration(
                    color: ChartColors.main,
                    borderRadius: BorderRadius.horizontal(left: outer, right: both ? inner : outer),
                  ),
                ),
              if (gap > 0) SizedBox(width: gap),
              if (inUse > 0)
                Container(
                  width: math.max(0, usedW - gap / 2),
                  decoration: BoxDecoration(
                    color: ChartColors.soft,
                    borderRadius: BorderRadius.horizontal(left: both ? inner : outer, right: outer),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
