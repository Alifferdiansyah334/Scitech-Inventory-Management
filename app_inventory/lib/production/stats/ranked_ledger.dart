import 'package:flutter/material.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import 'chart_parts.dart';

typedef RankedRow = ({String? category, String label, double value, String text});

/// Ranked records in a chart group: each row keeps the item's category
/// shape with its rank, full name and measured share together.
class RankedLedger extends StatelessWidget {
  const RankedLedger({
    required this.title,
    required this.subtitle,
    required this.rows,
    this.period,
    this.empty,
    super.key,
  });
  final String title, subtitle;
  final String? period;
  final List<RankedRow> rows;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final max = rows.fold<double>(0, (a, r) => r.value > a ? r.value : a);
    return ChartCard(
      title: title,
      subtitle: subtitle,
      period: period,
      icon: Icons.leaderboard_rounded,
      shape: ExpressiveShape.cookie12,
      child: rows.isEmpty
          ? (empty ?? const SizedBox.shrink())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, row) in rows.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
                    child: _RankedRowTile(row: row, rank: i + 1, max: max),
                  ),
              ],
            ),
    );
  }
}

class _RankedRowTile extends StatelessWidget {
  const _RankedRowTile({required this.row, required this.rank, required this.max});
  final RankedRow row;
  final int rank;
  final double max;

  @override
  Widget build(BuildContext context) {
    final top = rank == 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ShapeIcon.category(row.category ?? '', size: 48),
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: _RankBadge(rank: rank, top: top),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(row.label, style: context.text.titleSmall),
              const SizedBox(height: AppSpace.xs),
              Text(
                row.text,
                style: context.text.bodySmall?.copyWith(color: AppColors.muted, fontFeatures: tabular),
              ),
              const SizedBox(height: AppSpace.sm + 2),
              MeterBar(
                fraction: max <= 0 ? 0 : row.value / max,
                color: top ? ChartColors.main : ChartColors.soft,
                height: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rank number on a small disc ringed with the card colour; the leader
/// takes the brand colour.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.top});
  final int rank;
  final bool top;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: top ? AppColors.brand : AppColors.high,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.card, width: 2),
    ),
    child: FittedBox(
      child: Text(
        '$rank',
        semanticsLabel: 'Peringkat $rank',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFeatures: tabular,
          color: top ? AppColors.onBrand : AppColors.ink,
        ),
      ),
    ),
  );
}
