part of '../controls.dart';

/// One floating shape spawned when the user types a character.
class _TypedGlyph {
  _TypedGlyph({
    required this.char,
    required this.x,
    required this.shape,
    required this.color,
    required this.onColor,
    required this.driftX,
    required this.spin,
  });
  final String char;
  final double x;
  final ExpressiveShape shape;
  final Color color, onColor;
  final double driftX, spin;
  double age = 0; // seconds
}

class _MiniShapeTrail extends StatelessWidget {
  const _MiniShapeTrail({required this.chars, required this.tones, required this.step});
  final List<String> chars;
  final List<(Color, Color)> tones;
  final int step;

  @override
  Widget build(BuildContext context) {
    final tail = chars.length <= 3 ? chars : chars.sublist(chars.length - 3);
    final base = (chars.length - tail.length).clamp(0, 1 << 20);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, ch) in tail.indexed)
          () {
            final idx = base + i;
            final tone = tones[idx % tones.length];
            final shape = _shapeCycle[idx % _shapeCycle.length];
            return Padding(
              padding: const EdgeInsets.only(left: 2),
              child: PopIn(
                key: ValueKey('trail-$idx-$ch'),
                child: SizedBox.square(
                  dimension: 24,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: tone.$1,
                      shape: ExpressiveShapeBorder(shape, rotation: (idx + step) * .3),
                    ),
                    child: Center(
                      child: Text(
                        ch.toUpperCase(),
                        style: context.text.labelSmall?.copyWith(
                          color: tone.$2,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }(),
      ],
    );
  }
}

class _SearchTypingGlyph extends StatelessWidget {
  const _SearchTypingGlyph({required this.glyph});

  final _TypedGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final g = glyph;
    const life = 1.15;
    final u = (g.age / life).clamp(0.0, 1.0);
    final pop = fastSpatialCurve.transform((u * 2.4).clamp(0.0, 1.0));
    final fade = u < .6 ? 1.0 : (1 - (u - .6) / .4).clamp(0.0, 1.0);
    return Positioned(
      left: g.x + g.driftX * u - 17,
      top: -8 - 42 * math.sin(u * math.pi * .85),
      child: IgnorePointer(
        child: Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: (.45 + .8 * pop) * (1 - .2 * u),
            child: SizedBox.square(
              dimension: 34,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: g.color,
                  shape: ExpressiveShapeBorder(
                    g.shape,
                    morphTo: ExpressiveShape.circle,
                    morph: u * .45,
                    rotation: g.spin * u,
                  ),
                ),
                child: Center(
                  child: Text(
                    g.char,
                    style: context.text.labelMedium?.copyWith(color: g.onColor, fontWeight: FontWeight.w800),
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

class _SearchShapeLetters extends StatelessWidget {
  const _SearchShapeLetters({required this.chars, required this.tones, required this.step});

  final List<String> chars;
  final List<(Color, Color)> tones;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final (i, ch) in chars.take(12).indexed)
            () {
              final tone = tones[i % tones.length];
              final shape = _shapeCycle[i % _shapeCycle.length];
              return PopIn(
                key: ValueKey('glyph-$i-$ch'),
                child: SizedBox.square(
                  dimension: 26,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: tone.$1,
                      shape: ExpressiveShapeBorder(shape, rotation: (i * .35) + (step * .12)),
                    ),
                    child: Center(
                      child: Text(
                        ch.toUpperCase(),
                        style: context.text.labelSmall?.copyWith(
                          color: tone.$2,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

class _EditorTypingGlyph extends StatelessWidget {
  const _EditorTypingGlyph({required this.glyph});

  final _TypedGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final g = glyph;
    const life = 1.15;
    final u = (g.age / life).clamp(0.0, 1.0);
    final pop = fastSpatialCurve.transform((u * 2.2).clamp(0.0, 1.0));
    final fade = u < .55 ? 1.0 : (1 - (u - .55) / .45).clamp(0.0, 1.0);
    return Positioned(
      left: g.x + g.driftX * u - 16,
      top: -6 - 38 * math.sin(u * math.pi * .85),
      child: IgnorePointer(
        child: Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: (.45 + .75 * pop) * (1 - .2 * u),
            child: SizedBox.square(
              dimension: 32,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: g.color,
                  shape: ExpressiveShapeBorder(g.shape, rotation: g.spin * u),
                ),
                child: Center(
                  child: Text(
                    g.char,
                    style: context.text.labelSmall?.copyWith(color: g.onColor, fontWeight: FontWeight.w800),
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
