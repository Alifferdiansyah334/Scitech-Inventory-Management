import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// The colour palettes as swatches, three per row (AgroLens palette
/// picker). Picking one re-themes the app and throws a burst of shapes in
/// the new palette. [selected] is null while wallpaper colours are in use.
class SchemeGrid extends StatelessWidget {
  const SchemeGrid({required this.selected, required this.onChanged, super.key});
  final SchemeKey? selected;
  final ValueChanged<SchemeKey> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 8.0;
      final width = ((box.maxWidth - 2 * gap) / 3).floorToDouble();
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final key in SchemeKey.values)
            SizedBox(
              width: width,
              child: _Swatch(
                scheme: key,
                selected: key == selected,
                onTap: (origin) {
                  if (key == selected) return;
                  HapticFeedback.mediumImpact();
                  final light = schemeFor(key, Brightness.light);
                  ShapeBurst.show(
                    context,
                    origin: origin,
                    colors: [key.seed, light.secondaryContainer, light.tertiary, light.primaryContainer],
                  );
                  onChanged(key);
                },
              ),
            ),
        ],
      );
    },
  );
}

/// One palette: its stable shape in the hero colour, a dot of the second
/// tone and the name. Selected: a tonal card, the shape turns and rounds
/// toward a circle and a check springs in.
class _Swatch extends StatefulWidget {
  const _Swatch({required this.scheme, required this.selected, required this.onTap});
  final SchemeKey scheme;
  final bool selected;
  final ValueChanged<Offset> onTap;

  @override
  State<_Swatch> createState() => _SwatchState();
}

class _SwatchState extends State<_Swatch> with SingleTickerProviderStateMixin {
  late final _sel = AnimationController.unbounded(vsync: this, value: widget.selected ? 1 : 0);
  final _shapeKey = GlobalKey();

  @override
  void didUpdateWidget(_Swatch old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    final target = widget.selected ? 1.0 : 0.0;
    reducedMotion(context) ? _sel.value = target : springTo(_sel, target, AppSprings.bouncy);
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.scheme;
    final palette = AppPalette.resolve(scheme: key, dark: false);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Palet ${key.label}',
      excludeSemantics: true,
      child: PressSpring(
        squash: .12,
        scale: .94,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTap(ShapeBurst.centerOf(_shapeKey.currentContext!)),
          child: AnimatedBuilder(
            animation: _sel,
            builder: (context, _) {
              final t = _sel.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(AppColors.low, AppColors.highest, t.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(20 + 4 * t),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                  child: Column(
                    children: [
                      SizedBox.square(
                        key: _shapeKey,
                        dimension: 58,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                  color: palette.hero,
                                  shape: ExpressiveShapeBorder(
                                    key.shape,
                                    morph: (t * .55).clamp(0.0, 1.0),
                                    rotation: t * math.pi / 4,
                                  ),
                                ),
                              ),
                            ),
                            // Second tone of the palette.
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: palette.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.low, width: 2.5),
                                ),
                              ),
                            ),
                            Center(
                              child: Transform.scale(
                                scale: t.clamp(0.0, 1.4),
                                child: Icon(Icons.check_rounded, color: palette.onHero, size: 26),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        key.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
