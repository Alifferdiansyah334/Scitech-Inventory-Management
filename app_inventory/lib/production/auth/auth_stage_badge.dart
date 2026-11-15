part of 'auth_stages.dart';

/// Registration scene: a Scitech ID card with category stickers; a tap
/// shuffles the stickers.
class AuthBadgeArt extends StatefulWidget {
  const AuthBadgeArt({super.key});

  @override
  State<AuthBadgeArt> createState() => _AuthBadgeArtState();
}

class _AuthBadgeArtState extends State<AuthBadgeArt> {
  int _shift = 0;

  @override
  Widget build(BuildContext context) => _Scene(
    label: 'Kartu identitas Scitech',
    hint: 'Ganti stiker kartu',
    onTap: () => setState(() => _shift++),
    period: const Duration(seconds: 5),
    builder: (context, s, t, kick) {
      final pal = context.palette;
      final scheme = context.colors;
      String cat(int i) => _categories[(i + _shift) % _categories.length];
      Widget sticker(int i, double left, double top, double phase) => Positioned(
        left: left,
        top: top + math.sin(2 * math.pi * (t + phase)) * 3,
        child: ShapeIcon.category(cat(i), size: s * .24),
      );
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Transform.rotate(
              angle: -.1 + kick * .18,
              child: Container(
                width: s * .62,
                height: s * .78,
                padding: EdgeInsets.all(s * .06),
                decoration: BoxDecoration(color: pal.onHero, borderRadius: BorderRadius.circular(s * .12)),
                child: Column(
                  children: [
                    Container(
                      width: s * .18,
                      height: s * .04,
                      decoration: ShapeDecoration(color: pal.hero.withValues(alpha: .22), shape: const StadiumBorder()),
                    ),
                    SizedBox(height: s * .05),
                    ShapeIcon(
                      icon: Icons.person_rounded,
                      shape: ExpressiveShape.flower8,
                      size: s * .26,
                      fill: scheme.secondaryContainer,
                      foreground: scheme.onSecondaryContainer,
                    ),
                    const Spacer(),
                    for (final w in [.4, .28]) ...[
                      Container(
                        width: s * w,
                        height: s * .035,
                        decoration: ShapeDecoration(
                          color: pal.hero.withValues(alpha: .18),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      SizedBox(height: s * .03),
                    ],
                  ],
                ),
              ),
            ),
          ),
          sticker(0, -s * .02, s * .04, 0),
          sticker(1, s * .76, s * .22, .33),
          sticker(2, s * .7, s * .72, .66),
        ],
      );
    },
  );
}
