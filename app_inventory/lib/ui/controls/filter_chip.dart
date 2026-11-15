part of '../controls.dart';

/// M3 Expressive filter chip whose corners and leading shape badge morph with
/// a spring on press and selection.
class ExpressiveFilterChip extends StatefulWidget {
  const ExpressiveFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.shape = ExpressiveShape.cookie9,
    this.icon = Icons.category_outlined,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final ExpressiveShape shape;
  final IconData icon;

  @override
  State<ExpressiveFilterChip> createState() => _ExpressiveFilterChipState();
}

class _ExpressiveFilterChipState extends State<ExpressiveFilterChip> with SingleTickerProviderStateMixin {
  late final _sel = AnimationController.unbounded(vsync: this, value: widget.selected ? 1 : 0);

  @override
  void didUpdateWidget(ExpressiveFilterChip old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      final target = widget.selected ? 1.0 : 0.0;
      reducedMotion(context) ? _sel.value = target : springTo(_sel, target, AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      button: true,
      selected: widget.selected,
      child: PressSpring(
        squash: .09,
        scale: .94,
        child: AnimatedBuilder(
          animation: _sel,
          builder: (context, _) {
            final press = PressSpring.progressOf(context)?.value ?? 0;
            final s = _sel.value;
            final t = s.clamp(0.0, 1.0);
            final radius = BorderRadius.circular((12 + 12 * math.max(t, press * .7)).clamp(10, 26).toDouble());
            final bg = Color.lerp(scheme.surfaceContainerLow, scheme.secondaryContainer, t)!;
            final fg = Color.lerp(scheme.onSurfaceVariant, scheme.onSecondaryContainer, t)!;
            final border = Color.lerp(scheme.outlineVariant, scheme.primary.withValues(alpha: .35), t)!;
            return Material(
              color: bg,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: RoundedRectangleBorder(borderRadius: radius),
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSelected();
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 6, 12 + 4 * t, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 24,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: Color.lerp(scheme.surfaceContainerHighest, scheme.primary, t),
                            shape: ExpressiveShapeBorder(
                              widget.shape,
                              morphTo: ExpressiveShape.circle,
                              morph: (press * .6 + s * .25).clamp(0, 1),
                              rotation: (s * .9 + press * .5) * math.pi / 4,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              widget.selected ? Icons.check_rounded : widget.icon,
                              size: 14,
                              color: Color.lerp(scheme.onSurfaceVariant, scheme.onPrimary, t),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        widget.label,
                        style: context.text.labelLarge?.copyWith(
                          color: fg,
                          fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
