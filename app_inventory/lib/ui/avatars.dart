import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'shapes.dart';

enum AvatarHair { short, long, bun, curly, cap, hijab }

/// One illustrated profile picture preset.
class AvatarPreset {
  const AvatarPreset({
    required this.background,
    required this.skin,
    required this.hair,
    required this.hairColor,
    required this.shirt,
    this.glasses = false,
  });
  final Color background, skin, hairColor, shirt;
  final AvatarHair hair;
  final bool glasses;
}

const avatarPresets = <AvatarPreset>[
  AvatarPreset(
    background: Color(0xFFD8E2FF),
    skin: Color(0xFFF1C7A5),
    hair: AvatarHair.short,
    hairColor: Color(0xFF2B1E16),
    shirt: Color(0xFF0F2C59),
  ),
  AvatarPreset(
    background: Color(0xFFCDEBF3),
    skin: Color(0xFFD9A07A),
    hair: AvatarHair.hijab,
    hairColor: Color(0xFF0B5C63),
    shirt: Color(0xFF0B5C63),
  ),
  AvatarPreset(
    background: Color(0xFFFFDBCA),
    skin: Color(0xFFA86B48),
    hair: AvatarHair.curly,
    hairColor: Color(0xFF1A1110),
    shirt: Color(0xFFB4470C),
  ),
  AvatarPreset(
    background: Color(0xFFE6DEFF),
    skin: Color(0xFFF1C7A5),
    hair: AvatarHair.long,
    hairColor: Color(0xFF4A3426),
    shirt: Color(0xFF4B3A82),
    glasses: true,
  ),
  AvatarPreset(
    background: Color(0xFFBBEFC1),
    skin: Color(0xFF6B4430),
    hair: AvatarHair.cap,
    hairColor: Color(0xFF2F5D3A),
    shirt: Color(0xFF2F5D3A),
  ),
  AvatarPreset(
    background: Color(0xFFFFD8E6),
    skin: Color(0xFFD9A07A),
    hair: AvatarHair.bun,
    hairColor: Color(0xFF2B1E16),
    shirt: Color(0xFF7A2152),
  ),
  AvatarPreset(
    background: Color(0xFFE3E2EC),
    skin: Color(0xFFA86B48),
    hair: AvatarHair.short,
    hairColor: Color(0xFF121212),
    shirt: Color(0xFF44474F),
    glasses: true,
  ),
  AvatarPreset(
    background: Color(0xFFFFE08A),
    skin: Color(0xFFD9A07A),
    hair: AvatarHair.hijab,
    hairColor: Color(0xFF7A2152),
    shirt: Color(0xFF7A2152),
  ),
];

/// Frame shapes the user can pick for their picture.
const avatarFrames = <ExpressiveShape>[
  ExpressiveShape.cookie9,
  ExpressiveShape.clover4,
  ExpressiveShape.sunny8,
  ExpressiveShape.gem,
  ExpressiveShape.circle,
];

/// Profile picture: a device photo when set, otherwise an illustrated preset,
/// clipped to an expressive [frame].
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.preset,
    this.photo,
    this.frame = ExpressiveShape.cookie9,
    this.size = 72,
    this.ring,
    this.semanticLabel = 'Foto profil',
    super.key,
  });
  final AvatarPreset preset;
  final Uint8List? photo;
  final ExpressiveShape frame;
  final double size;

  /// Optional outline drawn as a slightly larger copy of the frame.
  final Color? ring;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final border = ExpressiveShapeBorder(frame);
    final picture = ClipPath(
      clipper: ShapeBorderClipper(shape: border),
      child: SizedBox.square(
        dimension: size,
        child: photo != null
            ? Image.memory(photo!, fit: BoxFit.cover, gaplessPlayback: true)
            : CustomPaint(painter: _AvatarPainter(preset)),
      ),
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ring == null
          ? picture
          : SizedBox.square(
              dimension: size + 12,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: ring, shape: border),
                child: Center(child: picture),
              ),
            ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.a);
  final AvatarPreset a;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    canvas.save();
    canvas.scale(k);
    final fill = Paint()..isAntiAlias = true;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), fill..color = a.background);
    if (a.hair == AvatarHair.long) {
      canvas.drawPath(
        Path()
          ..moveTo(30, 40)
          ..cubicTo(30, 18, 70, 18, 70, 40)
          ..lineTo(73, 84)
          ..lineTo(27, 84)
          ..close(),
        fill..color = a.hairColor,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(14, 112)
        ..cubicTo(14, 82, 30, 70, 50, 70)
        ..cubicTo(70, 70, 86, 82, 86, 112)
        ..close(),
      fill..color = a.shirt,
    );
    canvas.drawRRect(RRect.fromLTRBR(44, 54, 56, 72, const Radius.circular(4)), fill..color = a.skin);
    if (a.hair == AvatarHair.hijab) {
      canvas.drawPath(
        Path()
          ..moveTo(24, 60)
          ..cubicTo(22, 20, 78, 20, 76, 60)
          ..lineTo(84, 112)
          ..lineTo(16, 112)
          ..close(),
        fill..color = a.hairColor,
      );
      canvas.drawOval(const Rect.fromLTWH(37, 30, 26, 31), fill..color = a.skin);
    } else {
      canvas.drawOval(const Rect.fromLTWH(35, 25, 30, 34), fill..color = a.skin);
    }
    fill.color = a.hairColor;
    switch (a.hair) {
      case AvatarHair.short:
      case AvatarHair.bun:
        canvas.drawPath(
          Path()
            ..moveTo(34, 44)
            ..cubicTo(31, 20, 69, 20, 66, 44)
            ..cubicTo(63, 33, 55, 31, 49, 33)
            ..cubicTo(43, 35, 37, 36, 34, 44)
            ..close(),
          fill,
        );
        if (a.hair == AvatarHair.bun) canvas.drawOval(const Rect.fromLTWH(41, 11, 18, 16), fill);
      case AvatarHair.long:
        canvas.drawPath(
          Path()
            ..moveTo(34, 42)
            ..cubicTo(32, 21, 68, 21, 66, 42)
            ..cubicTo(60, 32, 48, 30, 34, 42)
            ..close(),
          fill,
        );
      case AvatarHair.curly:
        for (final (x, y, r) in const [
          (38.0, 30.0, 7.0),
          (46.0, 25.0, 8.0),
          (55.0, 25.0, 8.0),
          (63.0, 30.0, 7.0),
          (34.0, 38.0, 5.5),
          (66.0, 38.0, 5.5),
        ]) {
          canvas.drawCircle(Offset(x, y), r, fill);
        }
      case AvatarHair.cap:
        canvas.drawPath(
          Path()
            ..moveTo(33, 38)
            ..cubicTo(33, 20, 67, 20, 67, 38)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(48, 36)
            ..lineTo(76, 36)
            ..cubicTo(76, 40, 72, 41, 66, 41)
            ..lineTo(48, 41)
            ..close(),
          fill,
        );
      case AvatarHair.hijab:
        break;
    }
    final ey = a.hair == AvatarHair.hijab ? 46.0 : 44.0;
    final ink = Paint()..color = const Color(0xFF1A1B1F);
    canvas.drawCircle(Offset(44, ey), 1.6, ink);
    canvas.drawCircle(Offset(56, ey), 1.6, ink);
    final line = Paint()
      ..color = const Color(0xFF1A1B1F)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    canvas.drawPath(
      Path()
        ..moveTo(45.5, ey + 7)
        ..cubicTo(47.5, ey + 9.5, 52.5, ey + 9.5, 54.5, ey + 7),
      line,
    );
    if (a.glasses) {
      line.strokeWidth = 1.4;
      canvas.drawCircle(Offset(43.5, ey), 4.5, line);
      canvas.drawCircle(Offset(56.5, ey), 4.5, line);
      canvas.drawLine(Offset(48, ey), Offset(52, ey), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.a != a;
}
