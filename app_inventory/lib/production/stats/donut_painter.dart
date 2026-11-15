part of 'donut_chart.dart';

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.buckets, required this.total, required this.selected, required this.palette});

  final Map<LoanBucket, int> buckets;
  final int total;
  final LoanBucket? selected;

  /// Colours are read from the palette; a scheme change must repaint.
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const baseRadius = 74.0;
    const baseStroke = 24.0;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        baseRadius,
        Paint()
          ..color = ChartColors.track
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke,
      );
      return;
    }
    final nonZero = LoanBucket.values.where((b) => buckets[b]! > 0).length;
    final gap = nonZero > 1 ? 0.045 : 0.0;
    var start = -math.pi / 2;
    const fullSweep = math.pi * 2;

    for (final bucket in LoanBucket.values) {
      final count = buckets[bucket]!;
      if (count <= 0) continue;
      final share = (count / total) * fullSweep;
      final sweep = math.max(0.01, share - gap);
      final isSel = selected == bucket;
      final radius = isSel ? baseRadius + 4 : baseRadius;
      final stroke = isSel ? baseStroke + 4 : baseStroke;
      final color = bucketColor(bucket);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + gap / 2,
        sweep,
        false,
        Paint()
          ..color = selected != null && !isSel ? color.withValues(alpha: 0.42) : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += share;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.buckets != buckets || old.total != total || old.selected != selected || !identical(old.palette, palette);
}
