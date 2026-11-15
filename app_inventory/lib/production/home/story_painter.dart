part of 'borrower_home.dart';

/// Line illustrations for the story steps, drawn stroke by stroke as
/// [progress] runs: 1 a magnifier over a box, 2 a clipboard with a check,
/// 3 a box with a return arrow. Each step is fitted from its own bounds so
/// it fills the art column.
class _StoryPainter extends CustomPainter {
  _StoryPainter({required this.step, required this.progress, required this.ink}) : super(repaint: progress);
  final int step;
  final Animation<double> progress;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = switch (step) {
      0 => const Rect.fromLTRB(40, 30, 266, 198),
      1 => const Rect.fromLTRB(56, 4, 246, 200),
      _ => const Rect.fromLTRB(52, 16, 266, 196),
    };
    final scale = math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.translate((size.width - bounds.width * scale) / 2, (size.height - bounds.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);

    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void stroke(Path path, double start, double end, {bool fill = false, double width = 3.8}) {
      final t = Curves.easeOutCubic.transform(((progress.value - start) / (end - start)).clamp(0.0, 1.0));
      if (t <= 0) return;
      if (fill) {
        canvas.drawPath(path, Paint()..color = ink.withValues(alpha: .2 * t));
      }
      pen
        ..color = ink
        ..strokeWidth = width;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * t), pen);
      }
    }

    // A cardboard box seen slightly from above: front, then lid and side.
    void box(Rect front, Offset depth, double start, double end) {
      final mid = start + (end - start) * .45;
      stroke(Path()..addRect(front), start, mid, fill: true);
      final top = Path()
        ..moveTo(front.left, front.top)
        ..lineTo(front.left + depth.dx, front.top - depth.dy)
        ..lineTo(front.right + depth.dx, front.top - depth.dy)
        ..lineTo(front.right, front.top)
        ..close();
      stroke(top, mid - .05, end, fill: true);
      stroke(
        Path()
          ..moveTo(front.right + depth.dx, front.top - depth.dy)
          ..lineTo(front.right + depth.dx, front.bottom - depth.dy)
          ..lineTo(front.right, front.bottom),
        mid,
        end,
      );
      // Tape across the lid and a label on the front.
      final cx = front.center.dx;
      stroke(
        Path()
          ..moveTo(cx, front.top)
          ..lineTo(cx + depth.dx, front.top - depth.dy),
        end - .08,
        end + .06,
      );
      stroke(
        Path()..addRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(front.left + 14, front.top + 18, 40, 24), const Radius.circular(6)),
        ),
        end - .02,
        end + .14,
        width: 3.2,
      );
    }

    void sparkle(Offset c, double r, double start, double end) => stroke(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx, c.dy + r)
        ..moveTo(c.dx - r, c.dy)
        ..lineTo(c.dx + r, c.dy),
      start,
      end,
    );

    if (step == 0) {
      box(const Rect.fromLTWH(70, 112, 110, 80), const Offset(30, 24), 0, .4);
      stroke(Path()..addOval(Rect.fromCircle(center: const Offset(196, 86), radius: 42)), .45, .7, fill: true);
      stroke(
        Path()
          ..moveTo(176, 66)
          ..quadraticBezierTo(184, 58, 196, 58),
        .62,
        .76,
        width: 3.2,
      );
      stroke(
        Path()
          ..moveTo(226, 116)
          ..lineTo(256, 148),
        .7,
        .88,
        width: 7,
      );
      sparkle(const Offset(62, 54), 10, .82, 1);
      sparkle(const Offset(254, 46), 7, .88, 1);
    } else if (step == 1) {
      stroke(
        Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(84, 22, 120, 172), const Radius.circular(20))),
        0,
        .32,
        fill: true,
      );
      stroke(
        Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(116, 8, 56, 28), const Radius.circular(12))),
        .2,
        .4,
        fill: true,
      );
      for (var i = 0; i < 3; i++) {
        final y = 70.0 + i * 32;
        final from = .38 + i * .1;
        stroke(
          Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(102, y - 10, 20, 20), const Radius.circular(6))),
          from,
          from + .16,
          width: 3.2,
        );
        stroke(
          Path()
            ..moveTo(136, y)
            ..lineTo(186 - i * 14, y),
          from + .06,
          from + .22,
        );
      }
      stroke(Path()..addOval(Rect.fromCircle(center: const Offset(208, 166), radius: 28)), .72, .9, fill: true);
      stroke(
        Path()
          ..moveTo(195, 166)
          ..lineTo(205, 176)
          ..lineTo(222, 156),
        .86,
        1,
        width: 4.4,
      );
      sparkle(const Offset(66, 52), 9, .9, 1);
    } else {
      box(const Rect.fromLTWH(62, 108, 112, 82), const Offset(28, 22), 0, .42);
      // Return arrow curling back over the box.
      const center = Offset(224, 60);
      const r = 32.0;
      const from = .15 * math.pi, sweep = 1.45 * math.pi;
      stroke(Path()..addArc(Rect.fromCircle(center: center, radius: r), from, sweep), .5, .82, width: 4.4);
      const end = from + sweep;
      final tip = center + Offset(math.cos(end), math.sin(end)) * r;
      final dir = Offset(-math.sin(end), math.cos(end));
      final normal = Offset(-dir.dy, dir.dx);
      final back = tip - dir * 14;
      stroke(
        Path()
          ..moveTo(back.dx + normal.dx * 11, back.dy + normal.dy * 11)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(back.dx - normal.dx * 11, back.dy - normal.dy * 11),
        .8,
        .94,
        width: 4.4,
      );
      sparkle(const Offset(70, 56), 9, .9, 1);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StoryPainter oldDelegate) =>
      oldDelegate.step != step || oldDelegate.ink != ink || oldDelegate.progress != progress;
}
