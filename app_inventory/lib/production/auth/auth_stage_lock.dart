part of 'auth_stages.dart';

/// New-password scene: a padlock wrapped by orbiting password dots. It
/// closes when both entries are ready to save (input state, not saved).
class AuthLockArt extends StatelessWidget {
  const AuthLockArt({required this.locked, super.key});
  final bool locked;

  @override
  Widget build(BuildContext context) => _Scene(
    label: 'Gembok kata sandi baru',
    value: locked ? 'Isian sandi cocok, belum disimpan' : 'Lengkapi dan ulangi sandi baru',
    hint: 'Goyangkan gembok',
    period: const Duration(seconds: 16),
    builder: (context, s, t, kick) {
      final pal = context.palette;
      final scheme = context.colors;
      final still = reducedMotion(context);
      final center = Offset(s / 2, s / 2);
      final dot = s * .15;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 4; i++)
            () {
              final a = 2 * math.pi * (t + i / 4);
              final p = center + Offset(math.cos(a), math.sin(a)) * s * .4;
              return Positioned(
                left: p.dx - dot / 2,
                top: p.dy - dot / 2,
                child: ShapeIcon(
                  icon: Icons.emergency_rounded,
                  shape: ExpressiveShape.flower8,
                  size: dot,
                  fill: i.isEven ? scheme.secondaryContainer : scheme.tertiaryContainer,
                  foreground: i.isEven ? scheme.onSecondaryContainer : scheme.onTertiaryContainer,
                  iconScale: .5,
                ),
              );
            }(),
          Center(
            child: Transform.rotate(
              angle: math.sin(kick * math.pi) * .16,
              child: AnimatedSwitcher(
                duration: still ? Duration.zero : const Duration(milliseconds: 240),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: ShapeIcon(
                  key: ValueKey(locked),
                  icon: locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  shape: locked ? ExpressiveShape.cookie12 : ExpressiveShape.pentagon,
                  size: s * .5,
                  fill: pal.onHero,
                  foreground: pal.hero,
                  iconScale: .46,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
