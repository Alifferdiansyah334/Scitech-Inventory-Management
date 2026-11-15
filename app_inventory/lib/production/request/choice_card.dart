import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// Selectable card in the AgroLens crop-card recipe, placed on a tonal group
/// card: white with radius 24 when idle; picked, it fills with the secondary
/// container, tightens to radius 16, its shape turns and the check shape
/// pops in (spring).
class ChoiceCard extends StatefulWidget {
  const ChoiceCard({
    required this.title,
    required this.icon,
    required this.shape,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final ExpressiveShape shape;
  final bool selected;

  /// Null disables the card (while the request is being sent).
  final VoidCallback? onTap;

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _sel = AnimationController.unbounded(vsync: this, value: widget.selected ? 1 : 0);

  @override
  void didUpdateWidget(ChoiceCard old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    final target = widget.selected ? 1.0 : 0.0;
    reducedMotion(context) ? _sel.value = target : springTo(_sel, target, AppSprings.defaultSpatial);
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: widget.selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: AnimatedBuilder(
        animation: _sel,
        builder: (context, _) {
          final t = _sel.value.clamp(0.0, 1.0);
          final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24 - 8 * t));
          return PressSpring(
            enabled: widget.onTap != null,
            scale: .97,
            squash: .05,
            child: Material(
              color: Color.lerp(AppColors.card, AppColors.secondary, t),
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: shape,
                onTap: widget.onTap == null
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        widget.onTap!();
                      },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _badge(t),
                          const Spacer(),
                          Transform.scale(
                            scale: _sel.value.clamp(0.0, 1.2),
                            child: ShapeIcon(
                              icon: Icons.check_rounded,
                              shape: ExpressiveShape.cookie9,
                              size: 28,
                              fill: AppColors.brand,
                              foreground: AppColors.onBrand,
                              iconScale: .6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(widget.title, style: text.titleMedium),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: text.bodySmall?.copyWith(color: AppColors.muted, fontFeatures: tabular),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The option's shape, turning as it is picked; the icon stays upright.
  Widget _badge(double t) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ShapeClip(
              shape: widget.shape,
              rotation: t * .5,
              child: ColoredBox(color: Color.lerp(AppColors.secondary, AppColors.brand, t)!),
            ),
          ),
          Icon(widget.icon, size: 19, color: Color.lerp(AppColors.onSecondary, AppColors.onBrand, t)),
        ],
      ),
    ),
  );
}

/// Cards two per row with equal heights (one per row when narrow or with
/// large text).
class ChoiceGrid extends StatelessWidget {
  const ChoiceGrid({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 24;
      final columns = box.maxWidth >= 560 && !large
          ? 3
          : box.maxWidth >= 260 && !large
          ? 2
          : 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: 10),
                    Expanded(child: start + c < children.length ? children[start + c] : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
