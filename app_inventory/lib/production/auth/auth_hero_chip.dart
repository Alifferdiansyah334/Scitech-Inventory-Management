part of 'auth_hero.dart';

extension _AuthHeroChip on _AuthHeroState {
  Widget _chip() {
    final step = widget.step;
    final pal = context.palette;
    final label = step.flow.length > 1 ? '${step.chip} · ${step.index + 1} dari ${step.flow.length}' : step.chip;
    return DecoratedBox(
      decoration: ShapeDecoration(color: pal.onHero.withValues(alpha: .16), shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShapeIcon(
              icon: step.chipIcon,
              shape: authStageShapes[step.stage],
              size: 22,
              fill: pal.onHero,
              foreground: pal.hero,
              iconScale: .6,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: context.text.labelMedium?.copyWith(color: pal.onHero, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
