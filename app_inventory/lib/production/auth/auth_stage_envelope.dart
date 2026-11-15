part of 'auth_stages.dart';

/// Code scene: six code bubbles rising from the envelope fill as digits are
/// typed. Filled bubbles mean entered, never verified. A tap flips the
/// envelope to a "keep it secret" shield.
class AuthEnvelopeArt extends StatefulWidget {
  const AuthEnvelopeArt({required this.filled, super.key});
  final int filled;

  @override
  State<AuthEnvelopeArt> createState() => _AuthEnvelopeArtState();
}

class _AuthEnvelopeArtState extends State<AuthEnvelopeArt> {
  bool _secret = false;

  @override
  Widget build(BuildContext context) => _Scene(
    label: _secret ? 'Kode hanya untuk Anda, jangan bagikan' : 'Amplop kode verifikasi',
    value: '${widget.filled} dari 6 digit diisi',
    hint: _secret ? 'Tampilkan amplop' : 'Tampilkan pengingat keamanan',
    onTap: () => setState(() => _secret = !_secret),
    period: const Duration(seconds: 4),
    builder: (context, s, t, kick) {
      final pal = context.palette;
      final scheme = context.colors;
      final still = reducedMotion(context);
      final hub = Offset(s / 2, s * .66);
      final bubble = s * .16;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 6; i++)
            () {
              final a = math.pi * (1.08 + .84 * i / 5);
              final on = i < widget.filled;
              final p = hub + Offset(math.cos(a), math.sin(a)) * s * .46;
              final lift = math.sin(2 * math.pi * (t + i / 6)) * 3;
              return Positioned(
                left: p.dx - bubble / 2,
                top: p.dy - bubble / 2 + lift,
                child: AnimatedScale(
                  scale: on ? 1.12 : .86,
                  duration: still ? Duration.zero : fastSpatialCurve.duration,
                  curve: fastSpatialCurve,
                  child: AnimatedContainer(
                    duration: still ? Duration.zero : const Duration(milliseconds: 180),
                    width: bubble,
                    height: bubble,
                    decoration: on
                        ? ShapeDecoration(
                            color: scheme.tertiaryContainer,
                            shape: const ExpressiveShapeBorder(ExpressiveShape.cookie9),
                          )
                        : ShapeDecoration(
                            color: pal.onHero.withValues(alpha: .08),
                            shape: CircleBorder(side: BorderSide(color: pal.onHero.withValues(alpha: .4), width: 1.5)),
                          ),
                    child: on ? Icon(Icons.circle, size: bubble * .32, color: scheme.onTertiaryContainer) : null,
                  ),
                ),
              );
            }(),
          Positioned(
            left: hub.dx - s * .26,
            top: hub.dy - s * .26,
            child: Transform.rotate(
              angle: kick * .2,
              child: AnimatedSwitcher(
                duration: still ? Duration.zero : const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: ShapeIcon(
                  key: ValueKey(_secret),
                  icon: _secret ? Icons.shield_rounded : Icons.mark_email_unread_rounded,
                  shape: _secret ? ExpressiveShape.cookie12 : ExpressiveShape.sunny8,
                  size: s * .52,
                  fill: pal.onHero,
                  foreground: pal.hero,
                  iconScale: .44,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
