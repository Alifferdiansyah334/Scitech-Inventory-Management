import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/playground.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// Expressive hardware equipment crate ("rak alat") on the brand hero:
/// a rounded case chassis holding a [BallPit], top carry handle, dual snap
/// latches, subtle side rack ticks and corner bumpers. Tapping the top bar
/// shakes the balls. Laid out at [width] × [height]; scale from outside.
class InventoryCrate extends StatefulWidget {
  const InventoryCrate({required this.balls, required this.pitKey, required this.shakeLabel, super.key});

  /// Balls in the crate; [pitKey] changes when a different set is placed.
  final List<PitBall> balls;
  final Key pitKey;

  /// Screen reader label of the lid.
  final String shakeLabel;

  static const width = 142.0, height = 186.0;

  /// Ball radius that fills about half the crate for [count] balls.
  static double ballRadius(int count) =>
      count == 0 ? 0 : math.sqrt(138 * 142 * .48 / (count * math.pi)).clamp(17.5, 27.5);

  /// One category ball: the category shape with a rim in [rim].
  static Widget ball(Color rim, String category) {
    final style = categoryStyle(category);
    final (fill, ink) = AppColors.category(style.tone);
    return DecoratedBox(
      decoration: ShapeDecoration(color: rim, shape: ExpressiveShapeBorder(style.shape)),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: LayoutBuilder(
          builder: (context, box) => ShapeIcon(
            icon: style.icon,
            shape: style.shape,
            size: box.maxWidth,
            fill: fill,
            foreground: ink,
            iconScale: .5,
          ),
        ),
      ),
    );
  }

  @override
  State<InventoryCrate> createState() => _InventoryCrateState();
}

class _InventoryCrateState extends State<InventoryCrate> {
  final _shake = ValueNotifier<int>(0);

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = context.palette.onHero;
    return SizedBox(
      width: InventoryCrate.width,
      height: InventoryCrate.height,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            right: 2,
            top: 18,
            bottom: 2,
            child: ClipPath(
              clipper: _CrateClipper(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [on.withValues(alpha: .08), on.withValues(alpha: .16)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: BallPit(
                      key: widget.pitKey,
                      balls: widget.balls,
                      height: 142,
                      shakeOnEmptyTap: true,
                      shakeTrigger: _shake,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: CrateFramePainter(ink: on)),
            ),
          ),
          // Tapping the lid shakes the crate.
          Positioned(
            left: 10,
            right: 10,
            top: 0,
            height: 28,
            child: Semantics(
              button: true,
              label: widget.shakeLabel,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _shake.value++),
            ),
          ),
        ],
      ),
    );
  }
}

/// Equipment case body: crisper top corners under the lid, rounded bottom.
Path _crateBody(Size size) => Path()
  ..addRRect(
    RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: const Radius.circular(22),
      bottomRight: const Radius.circular(22),
    ),
  );

class _CrateClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _crateBody(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Hardware storage case outline: top carry handle, lid bar with dual
/// snap latches, subtle shelf ticks and reinforced bottom corner bumpers.
class CrateFramePainter extends CustomPainter {
  const CrateFramePainter({required this.ink});
  final Color ink;

  Paint _line(double alpha, double width) => Paint()
    ..color = ink.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    canvas.save();
    canvas.translate(2, 18);
    final body = Size(w - 4, size.height - 20);
    canvas.drawPath(_crateBody(body), _line(.58, 1.8));

    // Subtle side rack tick marks for inventory calibration feel.
    final tick = _line(.22, 1.8);
    for (final y in [28.0, 48.0, 68.0]) {
      canvas.drawLine(Offset(8, y), Offset(16, y), tick);
    }

    // Subtle top-right hardware glint.
    canvas.drawLine(Offset(body.width - 11, 16), Offset(body.width - 11, 42), _line(.18, 2.4));

    // Reinforced bottom corner bumpers.
    final guard = _line(.48, 2.6);
    for (final (x, dx) in [(5.0, 1.0), (body.width - 5, -1.0)]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, body.height - 32)
          ..lineTo(x, body.height - 20)
          ..quadraticBezierTo(x, body.height - 5, x + dx * 15, body.height - 5)
          ..lineTo(x + dx * 26, body.height - 5),
        guard,
      );
    }
    canvas.restore();

    // Top carry handle arch.
    canvas.drawPath(
      Path()
        ..moveTo(w * .34, 8)
        ..lineTo(w * .36, 2)
        ..quadraticBezierTo(w * .5, 0, w * .64, 2)
        ..lineTo(w * .66, 8),
      _line(.65, 2.0),
    );

    // Case lid bar + dual snap latches.
    final lid = RRect.fromRectAndRadius(Rect.fromLTWH(w * .05, 8, w * .90, 12), const Radius.circular(6));
    canvas.drawRRect(lid, Paint()..color = ink.withValues(alpha: .24));
    canvas.drawRRect(lid, _line(.68, 1.6));
    for (final cx in [w * .20, w * .80]) {
      final clasp = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 15), width: 12, height: 10),
        const Radius.circular(3),
      );
      canvas.drawRRect(clasp, Paint()..color = ink.withValues(alpha: .36));
      canvas.drawRRect(clasp, _line(.75, 1.4));
    }
  }

  @override
  bool shouldRepaint(CrateFramePainter oldDelegate) => oldDelegate.ink != ink;
}
