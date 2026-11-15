part of 'item_editor.dart';

/// 'Bisa dipinjam' card after AgroLens' featured toggle: the badge morphs
/// sunny8 → cookie12 and the card rounds 22 → 28 into the secondary
/// container on a bouncy spring; turning it on bursts shapes.
class _LendableToggle extends StatefulWidget {
  const _LendableToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<_LendableToggle> createState() => _LendableToggleState();
}

class _LendableToggleState extends State<_LendableToggle> with SingleTickerProviderStateMixin {
  late final _sel = AnimationController.unbounded(vsync: this, value: widget.value ? 1 : 0);
  final _badgeKey = GlobalKey();

  @override
  void didUpdateWidget(_LendableToggle old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final target = widget.value ? 1.0 : 0.0;
      reducedMotion(context) ? _sel.value = target : springTo(_sel, target, AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  void _toggle() {
    final scheme = context.colors;
    HapticFeedback.selectionClick();
    final badge = _badgeKey.currentContext;
    if (badge != null && !widget.value) {
      ShapeBurst.show(
        context,
        origin: ShapeBurst.centerOf(badge),
        count: 14,
        colors: [scheme.primary, scheme.tertiary, scheme.secondary, context.palette.hero],
      );
    }
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final enabled = widget.onChanged != null;
    // One switch node for the whole card (as the remember toggle on sign-in):
    // the label, description and Switch read together.
    return MergeSemantics(
      child: PressSpring(
        enabled: enabled,
        scale: .97,
        squash: .07,
        child: AnimatedBuilder(
          animation: _sel,
          builder: (context, _) {
            final t = _sel.value.clamp(0.0, 1.0);
            final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(22 + 6 * t));
            final fg = Color.lerp(scheme.onSurface, scheme.onSecondaryContainer, t)!;
            return Material(
              color: Color.lerp(scheme.surfaceContainerLow, scheme.secondaryContainer, t),
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: shape,
                onTap: enabled ? _toggle : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox.square(
                        key: _badgeKey,
                        dimension: 42,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: Color.lerp(scheme.surfaceContainerHighest, scheme.primary, t),
                            shape: ExpressiveShapeBorder(
                              ExpressiveShape.sunny8,
                              morphTo: ExpressiveShape.cookie12,
                              morph: _sel.value.clamp(0, 1.25),
                              rotation: _sel.value * .8,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              widget.value ? Icons.storefront_rounded : Icons.visibility_off_outlined,
                              color: Color.lerp(scheme.onSurfaceVariant, scheme.onPrimary, t),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bisa dipinjam', style: context.text.titleSmall?.copyWith(color: fg)),
                            Text(
                              widget.value ? 'Tampil di katalog peminjam.' : 'Disembunyikan dari peminjam.',
                              style: context.text.bodySmall?.copyWith(color: fg.withValues(alpha: .8)),
                            ),
                          ],
                        ),
                      ),
                      Switch(value: widget.value, onChanged: widget.onChanged),
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

/// Server error next to the action that caused it; the draft stays.
class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadii.xl)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShapeIcon(
            icon: Icons.priority_high_rounded,
            shape: ExpressiveShape.burst,
            size: 28,
            fill: AppColors.onErrorContainer,
            foreground: AppColors.errorContainer,
            iconScale: .55,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: AppColors.onErrorContainer, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
