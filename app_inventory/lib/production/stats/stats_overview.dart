import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/motion.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import 'admin_stats.dart';
import 'chart_parts.dart';
import 'donut_chart.dart';

/// One period figure: counted-up [value] with [suffix], or [text] when the
/// figure is not a whole number (or missing). [alert] figures sit on the
/// deadline container.
typedef StatFigure = ({
  IconData icon,
  ExpressiveShape shape,
  int? value,
  String suffix,
  String text,
  String label,
  bool alert,
});

/// The page's one hero (open loans right now) beside or above the period
/// figures as white tiles. Wide screens put the hero left of a 3×2 tile
/// grid of the same height; phones stack it over 2 (or 3) columns.
class StatsOverview extends StatelessWidget {
  const StatsOverview({required this.stats, required this.figures, super.key});
  final AdminStats stats;
  final List<StatFigure> figures;

  static const _gap = AppSpace.md;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scaled = MediaQuery.textScalerOf(context).scale(14) > 18;
      final hero = _OpenLoansHero(stats: stats);
      if (box.maxWidth >= 860 && !scaled) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: hero),
              const SizedBox(width: AppSpace.lg),
              Expanded(flex: 3, child: _TileGrid(figures: figures, columns: 3, fill: true)),
            ],
          ),
        );
      }
      final columns = scaled
          ? (box.maxWidth >= 700 ? 3 : 1)
          : box.maxWidth >= 540
          ? 3
          : 2;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hero,
          const SizedBox(height: AppSpace.lg),
          _TileGrid(figures: figures, columns: columns),
        ],
      );
    },
  );
}

class _OpenLoansHero extends StatelessWidget {
  const _OpenLoansHero({required this.stats});
  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final b = stats.buckets;
    final chips = [
      for (final bucket in const [LoanBucket.waiting, LoanBucket.checking, LoanBucket.late])
        if (b[bucket]! > 0) (bucket, b[bucket]!),
    ];
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ShapeIcon(
                icon: Icons.swap_horiz_rounded,
                shape: ExpressiveShape.sunny8,
                size: 44,
                fill: AppColors.heroShape,
                foreground: AppColors.onHeroShape,
              ),
              const SizedBox(width: AppSpace.md),
              Flexible(
                child: Text('Saat ini', style: context.text.titleSmall?.copyWith(color: AppColors.onHero)),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: CountUp(
              stats.openLoans,
              style: context.text.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                height: 1,
                fontFeatures: tabular,
                color: AppColors.onHero,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs + 2),
          Text(
            'pinjaman masih terbuka',
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.onHero),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              if (chips.isEmpty) const _HeroChip(label: 'Tidak ada yang perlu ditindak', shape: ExpressiveShape.circle),
              for (final (bucket, count) in chips)
                _HeroChip(
                  label: '$count ${loanBucketLabels[bucket]!.toLowerCase()}',
                  shape: bucketShape(bucket),
                  late: bucket == LoanBucket.late,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Count chip on the hero: a pill on the soft hero tint, deadline container
/// only for late loans.
class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.shape, this.late = false});
  final String label;
  final ExpressiveShape shape;
  final bool late;

  @override
  Widget build(BuildContext context) {
    final fg = late ? AppColors.onDeadlineContainer : AppColors.onHero;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: late ? AppColors.deadlineContainer : AppColors.heroSoft,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShapeMarker(color: late ? AppColors.deadline : AppColors.heroShape, shape: shape, size: 16),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Text(label, style: context.text.labelMedium?.copyWith(color: fg, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

/// Figures as separate white tiles, equal height per line. With [fill] the
/// lines share the height the parent gives (beside the hero).
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.figures, required this.columns, this.fill = false});
  final List<StatFigure> figures;
  final int columns;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    const gap = StatsOverview._gap;
    final lines = [
      for (var i = 0; i < figures.length; i += columns) figures.sublist(i, (i + columns).clamp(0, figures.length)),
    ];
    Widget line(List<StatFigure> figs) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) const SizedBox(width: gap),
          Expanded(child: c < figs.length ? _StatTile(figs[c]) : const SizedBox.shrink()),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (r, figs) in lines.indexed) ...[
          if (r > 0) const SizedBox(height: gap),
          fill ? Expanded(child: line(figs)) : IntrinsicHeight(child: line(figs)),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.figure);
  final StatFigure figure;

  @override
  Widget build(BuildContext context) {
    final f = figure;
    final numberStyle = context.text.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -.8,
      height: 1.1,
      fontFeatures: tabular,
      color: f.alert ? AppColors.deadline : AppColors.ink,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: f.alert ? AppColors.deadlineContainer : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShapeIcon(
            icon: f.icon,
            shape: f.shape,
            size: 40,
            fill: f.alert ? AppColors.card : AppColors.secondary,
            foreground: f.alert ? AppColors.deadline : AppColors.onSecondary,
          ),
          const SizedBox(height: AppSpace.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: f.value == null
                ? Text(f.text, style: numberStyle)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountUp(f.value!, style: numberStyle),
                      if (f.suffix.isNotEmpty) Text(f.suffix, style: numberStyle),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            f.label,
            style: context.text.bodySmall?.copyWith(
              height: 1.35,
              color: f.alert ? AppColors.onDeadlineContainer : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
