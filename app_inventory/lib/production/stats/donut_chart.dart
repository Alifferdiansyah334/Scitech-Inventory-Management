import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'admin_stats.dart';
import 'chart_parts.dart';

const bucketColors = {
  LoanBucket.waiting: ChartColors.waiting,
  LoanBucket.ready: ChartColors.ok,
  LoanBucket.borrowed: ChartColors.navy,
  LoanBucket.checking: ChartColors.blue,
  LoanBucket.late: ChartColors.bad,
};

/// Interactive status donut: tap or hover a slice or legend row to inspect
/// its exact share and count in the centre gauge.
class LoanStatusDonut extends StatefulWidget {
  const LoanStatusDonut({required this.stats, super.key});
  final AdminStats stats;

  @override
  State<LoanStatusDonut> createState() => _LoanStatusDonutState();
}

class _LoanStatusDonutState extends State<LoanStatusDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
  );
  bool _started = false;
  LoanBucket? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reducedMotion(context)) {
      _progress.value = 1;
    } else {
      springTo(_progress, 1, AppSprings.gentle);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

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
    final shownLabel = sel == null
        ? 'pinjaman terbuka'
        : loanBucketLabels[sel]!;
    final pct = sel != null && total > 0
        ? '${(buckets[sel]! * 100 / total).round()}% dari terbuka'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => CustomPaint(
                          size: size,
                          painter: _DonutPainter(
                            buckets: buckets,
                            total: total,
                            progress: _progress.value.clamp(0.0, 1.0),
                            selected: sel,
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: SizedBox(
                          width: 118,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$shownCount',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  color: sel == null
                                      ? AppColors.ink
                                      : bucketColors[sel],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shownLabel,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                  height: 1.15,
                                ),
                              ),
                              if (pct != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  pct,
                                  style: const TextStyle(
                                    fontFamily: AppFonts.mono,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ],
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
        const SizedBox(height: 10),
        for (final bucket in LoanBucket.values)
          _BucketRow(
            bucket: bucket,
            count: buckets[bucket]!,
            total: total,
            selected: sel == bucket,
            onTap: () =>
                setState(() => _selected = _selected == bucket ? null : bucket),
            onHover: (hover) => setState(
              () => _selected = hover
                  ? bucket
                  : (_selected == bucket ? null : _selected),
            ),
          ),
      ],
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({
    required this.bucket,
    required this.count,
    required this.total,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  final LoanBucket bucket;
  final int count, total;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final color = bucketColors[bucket]!;
    final pct = total > 0 && count > 0
        ? '${(count * 100 / total).round()}%'
        : '';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: Material(
          color: selected ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loanBucketLabels[bucket]!,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (pct.isNotEmpty) ...[
                    Text(
                      pct,
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.surface : AppColors.paper,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.buckets,
    required this.total,
    required this.progress,
    required this.selected,
  });

  final Map<LoanBucket, int> buckets;
  final int total;
  final double progress;
  final LoanBucket? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const baseRadius = 74.0;
    const baseStroke = 24.0;
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = AppColors.paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseStroke,
    );
    if (total <= 0) return;

    final nonZero = LoanBucket.values.where((b) => buckets[b]! > 0).length;
    final gap = nonZero > 1 ? 0.045 : 0.0;
    var start = -math.pi / 2;
    final fullSweep = math.pi * 2 * progress;

    for (final bucket in LoanBucket.values) {
      final count = buckets[bucket]!;
      if (count <= 0) continue;
      final share = (count / total) * fullSweep;
      final sweep = math.max(0.01, share - gap);
      final isSel = selected == bucket;
      final radius = isSel ? baseRadius + 4 : baseRadius;
      final stroke = isSel ? baseStroke + 4 : baseStroke;
      final color = bucketColors[bucket]!;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + gap / 2,
        sweep,
        false,
        Paint()
          ..color = selected != null && !isSel
              ? color.withValues(alpha: 0.42)
              : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += share;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.buckets != buckets ||
      old.total != total ||
      old.progress != progress ||
      old.selected != selected;
}
