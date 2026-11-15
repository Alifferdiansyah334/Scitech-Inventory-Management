part of 'auth_hero.dart';

/// Small expressive shapes drifting on the hero (secondary/tertiary accents
/// and translucent white), like confetti that never lands. Decorative only.
class _Confetti extends StatelessWidget {
  const _Confetti();

  // (x, y as fraction of the hero, size, shape, tone, phase)
  static const _bits = [
    (.52, .04, 14.0, ExpressiveShape.sunny8, 0, .0),
    (.97, .62, 12.0, ExpressiveShape.flower8, 1, .3),
    (.62, .96, 16.0, ExpressiveShape.clover4, 2, .55),
    (.34, .97, 9.0, ExpressiveShape.gem, 0, .8),
    (.82, .04, 8.0, ExpressiveShape.circle, 1, .15),
    (.12, .98, 12.0, ExpressiveShape.cookie9, 2, .45),
    (.99, .30, 9.0, ExpressiveShape.circle, 0, .7),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final on = context.palette.onHero;
    final tones = [scheme.secondaryContainer, scheme.tertiaryContainer, on.withValues(alpha: .2)];
    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) => Ambient(
            period: const Duration(seconds: 9),
            builder: (context, t, _) => Stack(
              children: [
                for (final (x, y, size, shape, tone, phase) in _bits)
                  Positioned(
                    left: x * box.maxWidth - size / 2,
                    top: y * box.maxHeight - size / 2 + math.sin(2 * math.pi * (t + phase)) * 5,
                    child: Transform.rotate(
                      angle: 2 * math.pi * (t + phase) * (tone.isEven ? 1 : -1),
                      child: SizedBox.square(
                        dimension: size,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(color: tones[tone], shape: ExpressiveShapeBorder(shape)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
