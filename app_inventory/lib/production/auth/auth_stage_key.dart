part of 'auth_stages.dart';

/// Recovery scene: a key bobbing beside a locked account. A tap slides the
/// key into the lock and turns it (and back again); it is a toy, not a
/// recovery result.
class AuthKeyArt extends StatefulWidget {
  const AuthKeyArt({super.key});

  @override
  State<AuthKeyArt> createState() => _AuthKeyArtState();
}

class _AuthKeyArtState extends State<AuthKeyArt> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController.unbounded(vsync: this);
  bool _in = false;

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _in = !_in);
    final target = _in ? 1.0 : 0.0;
    reducedMotion(context) ? _turn.value = target : springTo(_turn, target, AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) => _Scene(
    label: 'Kunci pemulihan akun',
    hint: _in ? 'Cabut kunci' : 'Masukkan kunci ke gembok',
    onTap: _toggle,
    extra: _turn,
    period: const Duration(seconds: 5),
    builder: (context, s, t, kick) {
      final pal = context.palette;
      final scheme = context.colors;
      final k = _turn.value;
      final bob = math.sin(2 * math.pi * t) * 4 * (1 - k.clamp(0.0, 1.0));
      return Stack(
        clipBehavior: Clip.none,
        children: [
          _Sparkle(left: s * .04, top: s * .66, size: s * .1, t: t, phase: .2),
          _Sparkle(left: s * .78, top: s * .02, size: s * .12, t: t, phase: .6),
          Positioned(
            right: s * .02,
            bottom: s * .04,
            child: Transform.rotate(
              angle: math.sin(kick * math.pi) * .12,
              child: ShapeIcon(
                icon: k > .6 ? Icons.lock_open_rounded : Icons.lock_rounded,
                shape: ExpressiveShape.softBurst,
                size: s * .54,
                fill: pal.onHero,
                foreground: pal.hero,
                iconScale: .44,
              ),
            ),
          ),
          Positioned(
            left: s * (.02 + .2 * k),
            top: s * (.04 + .22 * k) + bob,
            child: Transform.rotate(
              angle: -.7 + k * (math.pi / 2 + .7) + kick * .25,
              child: ShapeIcon(
                icon: Icons.key_rounded,
                shape: ExpressiveShape.clover4,
                size: s * .42,
                fill: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
                iconScale: .5,
              ),
            ),
          ),
          Positioned(
            left: s * .44,
            top: s * .02,
            child: Bob(
              distance: 3,
              phase: .3,
              child: ShapeIcon(
                icon: Icons.question_mark_rounded,
                shape: ExpressiveShape.sunny8,
                size: s * .2,
                fill: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
                iconScale: .55,
              ),
            ),
          ),
        ],
      );
    },
  );
}
