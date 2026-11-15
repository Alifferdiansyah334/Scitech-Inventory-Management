part of '../controls.dart';

/// Destination in [ExpressiveNavBar].
class ExpressiveNavItem {
  const ExpressiveNavItem({required this.label, required this.icon, required this.selectedIcon, required this.shape});
  final String label;
  final IconData icon, selectedIcon;
  final ExpressiveShape shape;
}

/// M3 Expressive bottom navigation bar:
/// - the selected destination expands horizontally on a bouncy spring into a
///   pill while its icon sits inside a morphing [ExpressiveShapeBorder];
/// - holding any destination widens and squashes it like jelly;
/// - selecting a destination pops a small burst of shapes from its icon.
class ExpressiveNavBar extends StatefulWidget {
  const ExpressiveNavBar({required this.items, required this.selectedIndex, required this.onSelected, super.key});
  final List<ExpressiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<ExpressiveNavBar> createState() => _ExpressiveNavBarState();
}

class _ExpressiveNavBarState extends State<ExpressiveNavBar> with TickerProviderStateMixin {
  late final List<AnimationController> _press = [
    for (final _ in widget.items) AnimationController.unbounded(vsync: this),
  ];
  late final List<AnimationController> _select = [
    for (var i = 0; i < widget.items.length; i++)
      AnimationController.unbounded(vsync: this, value: i == widget.selectedIndex ? 1 : 0),
  ];
  late final List<GlobalKey> _iconKeys = [for (final _ in widget.items) GlobalKey()];

  @override
  void didUpdateWidget(ExpressiveNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      final still = reducedMotion(context);
      for (var i = 0; i < _select.length; i++) {
        final target = i == widget.selectedIndex ? 1.0 : 0.0;
        still ? _select[i].value = target : springTo(_select[i], target, AppSprings.bouncy);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [..._press, ..._select]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hold(int i, bool down) {
    if (reducedMotion(context)) return;
    springTo(_press[i], down ? 1 : 0, down ? AppSprings.fastSpatial : AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: .35))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: AnimatedBuilder(
              animation: Listenable.merge([..._press, ..._select]),
              builder: (context, _) => Row(
                children: [
                  for (var i = 0; i < widget.items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    () {
                      final item = widget.items[i];
                      final s = _select[i].value;
                      final p = _press[i].value;
                      final t = s.clamp(0.0, 1.0);
                      final selected = i == widget.selectedIndex;
                      final flex = ((1 + .45 * s + .22 * p).clamp(.7, 2.0) * 1000).round();
                      final radius = BorderRadius.circular((16 + 14 * math.max(t, p * .6)).clamp(14, 30).toDouble());
                      final pillBg = Color.lerp(
                        scheme.surfaceContainerLow.withValues(alpha: 0),
                        scheme.secondaryContainer,
                        t,
                      )!;
                      final badgeBg = Color.lerp(Colors.transparent, scheme.primary, t)!;
                      final iconFg = Color.lerp(scheme.onSurfaceVariant, scheme.onPrimary, t)!;
                      final labelFg = Color.lerp(scheme.onSurfaceVariant, scheme.onSecondaryContainer, t)!;

                      return Expanded(
                        flex: flex,
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: item.label,
                          child: Listener(
                            onPointerDown: (_) => _hold(i, true),
                            onPointerUp: (_) => _hold(i, false),
                            onPointerCancel: (_) => _hold(i, false),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(1 + .05 * p, 1 - .06 * p, 1),
                              child: Material(
                                color: pillBg,
                                shape: RoundedRectangleBorder(borderRadius: radius),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  customBorder: RoundedRectangleBorder(borderRadius: radius),
                                  onTap: () {
                                    if (i != widget.selectedIndex) {
                                      HapticFeedback.selectionClick();
                                      final ctx = _iconKeys[i].currentContext;
                                      if (ctx != null) {
                                        ShapeBurst.show(
                                          context,
                                          origin: ShapeBurst.centerOf(ctx),
                                          count: 12,
                                          colors: [
                                            scheme.primary,
                                            scheme.tertiary,
                                            scheme.secondary,
                                            context.palette.hero,
                                          ],
                                        );
                                      }
                                    }
                                    widget.onSelected(i);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox.square(
                                          key: _iconKeys[i],
                                          dimension: 34,
                                          child: DecoratedBox(
                                            decoration: ShapeDecoration(
                                              color: badgeBg,
                                              shape: ExpressiveShapeBorder(
                                                ExpressiveShape.circle,
                                                morphTo: item.shape,
                                                morph: (s + p * .45).clamp(0, 1.25),
                                                rotation: (s * .65 + p * .35) * math.pi / 3,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                selected ? item.selectedIcon : item.icon,
                                                size: 20,
                                                color: iconFg,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.labelSmall?.copyWith(
                                            color: labelFg,
                                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
