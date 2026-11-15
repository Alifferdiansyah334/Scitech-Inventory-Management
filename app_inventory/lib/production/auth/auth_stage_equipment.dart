part of 'auth_stages.dart';

/// Equipment categories orbiting the inventory hub; matches the catalogue's
/// own category shapes and tints.
const _categories = ['Kamera', 'Drone', 'Audio', 'Proyektor', 'Perkakas'];

/// Sign-in scene: the Scitech inventory box with its equipment categories
/// on a slow orbit. A tap spins the orbit on a bouncy spring and brings the
/// next category forward.
class AuthEquipmentArt extends StatefulWidget {
  const AuthEquipmentArt({super.key});

  @override
  State<AuthEquipmentArt> createState() => _AuthEquipmentArtState();
}

class _AuthEquipmentArtState extends State<AuthEquipmentArt> with SingleTickerProviderStateMixin {
  late final _spin = AnimationController.unbounded(vsync: this);
  int _focus = 0;

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _focus = (_focus + 1) % _categories.length);
    final target = (_spin.value + 1).roundToDouble();
    reducedMotion(context) ? _spin.value = target : springTo(_spin, target, AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) => _Scene(
    label: 'Kategori perlengkapan Scitech',
    value: _categories[_focus],
    hint: 'Putar ke kategori berikutnya',
    onTap: _next,
    extra: _spin,
    period: const Duration(seconds: 28),
    builder: (context, s, t, kick) {
      final pal = context.palette;
      final center = Offset(s / 2, s / 2);
      final r = s * .36;
      // Each tap turns the ring by one slot so the next category lands on top.
      final turn = _spin.value * 2 * math.pi / _categories.length;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(s / 2 - r),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: pal.onHero.withValues(alpha: .24), width: 1.5),
                ),
              ),
            ),
          ),
          for (var i = 0; i < _categories.length; i++)
            () {
              final a = -math.pi / 2 + 2 * math.pi * (t + i / _categories.length) - turn;
              final focus = i == _focus;
              final size = s * (focus ? .3 : .23);
              final p = center + Offset(math.cos(a), math.sin(a)) * r;
              return Positioned(
                left: p.dx - size / 2,
                top: p.dy - size / 2,
                child: AnimatedContainer(
                  duration: reducedMotion(context) ? Duration.zero : fastSpatialCurve.duration,
                  curve: fastSpatialCurve,
                  width: size,
                  height: size,
                  child: FittedBox(child: ShapeIcon.category(_categories[i], size: 40)),
                ),
              );
            }(),
          Center(
            child: Transform.rotate(
              angle: kick * .22,
              child: Transform.scale(
                scale: 1 + kick * .08,
                child: ShapeIcon(
                  icon: Icons.inventory_2_rounded,
                  shape: ExpressiveShape.cookie12,
                  size: s * .4,
                  fill: pal.onHero,
                  foreground: pal.hero,
                  iconScale: .48,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
