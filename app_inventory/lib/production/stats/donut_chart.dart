import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'admin_stats.dart';
import 'chart_parts.dart';

part 'donut_painter.dart';

/// Bucket colours from palette roles: brand for loans out, ok for ready,
/// deadline orange only for late, neutral for waiting on an admin.
Color bucketColor(LoanBucket bucket) => switch (bucket) {
  LoanBucket.waiting => ChartColors.neutral,
  LoanBucket.ready => ChartColors.ok,
  LoanBucket.borrowed => ChartColors.main,
  LoanBucket.checking => ChartColors.soft,
  LoanBucket.late => ChartColors.overdue,
};

/// Bucket legend shapes, matching the status tone shapes: sunny for waiting
/// on a person, circle for ready, cookie for out, burst for late.
ExpressiveShape bucketShape(LoanBucket bucket) => switch (bucket) {
  LoanBucket.waiting => ExpressiveShape.sunny8,
  LoanBucket.ready => ExpressiveShape.circle,
  LoanBucket.borrowed => ExpressiveShape.cookie9,
  LoanBucket.checking => ExpressiveShape.clover4,
  LoanBucket.late => ExpressiveShape.burst,
};

/// Interactive status donut with a text summary and selectable legend.
class LoanStatusDonut extends StatefulWidget {
  const LoanStatusDonut({required this.stats, super.key});
  final AdminStats stats;

  @override
  State<LoanStatusDonut> createState() => _LoanStatusDonutState();
}

class _LoanStatusDonutState extends State<LoanStatusDonut> {
  LoanBucket? _selected;

  void _pickAt(Offset local, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = local - center;
    final dist = delta.distance;
    if (dist < 44 || dist > 98) {
      if (_selected != null) setState(() => _selected = null);
      return;
    }
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    final total = widget.stats.openLoans;
    if (total <= 0) return;
    var cursor = 0.0;
    for (final bucket in LoanBucket.values) {
      final count = widget.stats.buckets[bucket]!;
      if (count <= 0) continue;
      final sweep = (count / total) * math.pi * 2;
      if (angle >= cursor && angle <= cursor + sweep) {
        if (_selected != bucket) setState(() => _selected = bucket);
        return;
      }
      cursor += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.stats.buckets;
    final total = widget.stats.openLoans;
    final sel = _selected;
    final shownCount = sel == null ? total : buckets[sel]!;
    final shownLabel = sel == null ? 'pinjaman terbuka' : loanBucketLabels[sel]!;
    final share = sel != null && total > 0 ? (buckets[sel]! * 100 / total).round() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$shownCount ',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                  color: sel == null ? AppColors.ink : bucketInk(sel),
                ),
              ),
              TextSpan(
                text: shownLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (share != null)
                TextSpan(
                  text: ' · $share% dari terbuka',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.muted),
                ),
            ],
          ),
          style: TextStyle(fontFeatures: tabular, color: AppColors.ink, height: 1.3),
        ),
        const SizedBox(height: AppSpace.sm),
        SizedBox(
          height: 204,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = Size(box.maxWidth, 204);
              return MouseRegion(
                onHover: (e) => _pickAt(e.localPosition, size),
                onExit: (_) => setState(() => _selected = null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (e) => _pickAt(e.localPosition, size),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: size,
                        painter: _DonutPainter(
                          buckets: buckets,
                          total: total,
                          selected: sel,
                          palette: AppPalette.current,
                        ),
                      ),
                      // Hole label: the share of the chosen status, or the
                      // open total; the full sentence is the heading above.
                      ExcludeSemantics(
                        child: SizedBox(
                          width: 84,
                          height: 56,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              share == null ? '$total' : '$share%',
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.8,
                                fontFeatures: tabular,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.md),
        for (final bucket in LoanBucket.values)
          _BucketRow(
            bucket: bucket,
            count: buckets[bucket]!,
            total: total,
            selected: sel == bucket,
            first: bucket == LoanBucket.values.first,
            last: bucket == LoanBucket.values.last,
            onTap: () => setState(() => _selected = _selected == bucket ? null : bucket),
            onHover: (hover) => setState(() => _selected = hover ? bucket : (_selected == bucket ? null : _selected)),
          ),
      ],
    );
  }
}

/// Text colour for a bucket's figure: deadline only for late.
Color bucketInk(LoanBucket bucket) => bucket == LoanBucket.late ? AppColors.deadline : AppColors.ink;

class _BucketRow extends StatelessWidget {
  const _BucketRow({
    required this.bucket,
    required this.count,
    required this.total,
    required this.selected,
    required this.first,
    required this.last,
    required this.onTap,
    required this.onHover,
  });

  final LoanBucket bucket;
  final int count, total;
  final bool selected, first, last;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 && count > 0 ? '${(count * 100 / total).round()}%' : '';
    // Legend rows form one connected list on the low surface; the chosen
    // row springs into a pill in the selection colour.
    final radius = selected
        ? BorderRadius.circular(AppRadii.full)
        : BorderRadius.vertical(
            top: Radius.circular(first ? AppRadii.lgPlus : AppRadii.listInner),
            bottom: Radius.circular(last ? AppRadii.lgPlus : AppRadii.listInner),
          );
    final ink = selected ? AppColors.onSecondary : AppColors.ink;
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 3),
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: Semantics(
          container: true,
          button: true,
          selected: selected,
          child: PressSpring(
            scale: .98,
            squash: .04,
            child: AnimatedContainer(
              duration: reducedMotion(context) ? Duration.zero : fastSpatialCurve.duration,
              curve: fastSpatialCurve,
              decoration: BoxDecoration(color: selected ? AppColors.secondary : AppColors.card, borderRadius: radius),
              clipBehavior: Clip.antiAlias,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        ShapeMarker(color: bucketColor(bucket), shape: bucketShape(bucket), size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loanBucketLabels[bucket]!,
                            style: TextStyle(
                              fontSize: 14,
                              color: ink,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Text(
                            '$count${pct.isEmpty ? '' : ' · $pct'}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFeatures: tabular,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
