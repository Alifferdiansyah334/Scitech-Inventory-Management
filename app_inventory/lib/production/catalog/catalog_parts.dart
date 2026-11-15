import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/controls.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

part 'catalog_status.dart';

/// Lets a horizontal strip run under the page's 16 px side padding to the
/// screen edges, as AgroLens' full-bleed library strips do.
class _Bleed extends StatelessWidget {
  const _Bleed({required this.height, required this.by, required this.child});
  final double height, by;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, box) =>
          OverflowBox(minWidth: box.maxWidth + by * 2, maxWidth: box.maxWidth + by * 2, child: child),
    ),
  );
}

/// AgroLens library category strip (library_tab): 'Semua' and every
/// category with its own shape and icon, then the 'Tersedia' toggle. One
/// swipeable row 60 tall on phones (padding 16/12/16/6, gap 8, bleeding to
/// the screen edges); wrapped on wide panes.
class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.availableOnly,
    required this.onAvailable,
    this.wrap = false,
    super.key,
  });

  /// Category names with their item counts ('Semua' first).
  final List<(String, int)> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool availableOnly;
  final ValueChanged<bool> onAvailable;
  final bool wrap;

  Widget _filter(String name, int count) {
    final all = name == 'Semua';
    final style = categoryStyle(name);
    return Semantics(
      label: '$name, $count barang',
      excludeSemantics: true,
      button: true,
      selected: name == selected,
      onTap: () => onSelect(name),
      child: ExpressiveFilterChip(
        label: name,
        selected: name == selected,
        onSelected: () => onSelect(name),
        shape: all ? ExpressiveShape.cookie12 : style.shape,
        icon: all ? Icons.grid_view_rounded : style.icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final (name, count) in categories) _filter(name, count),
      ExpressiveFilterChip(
        label: 'Tersedia',
        selected: availableOnly,
        onSelected: () => onAvailable(!availableOnly),
        shape: ExpressiveShape.circle,
        icon: Icons.check_circle_outline_rounded,
      ),
    ];
    if (wrap) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final chip in chips) FittedBox(fit: BoxFit.scaleDown, child: chip)],
        ),
      );
    }
    // 60 tall at 1x; grows with the chip label at large text sizes.
    final chipHeight = math.max(36.0, MediaQuery.textScalerOf(context).scale(20) + 14);
    return _Bleed(
      height: chipHeight + 24,
      by: 16,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        scrollDirection: Axis.horizontal,
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: chip),
            ),
        ],
      ),
    );
  }
}

/// AgroLens 'Pilihan' carousel (library_tab): 230 tall, weights 7:2 with
/// snapping and radius 28. Photos get the dark gradient with the category
/// in lime and the name in white; items without a photo show their
/// category tint with the category shape large. Text hides while an item
/// is squeezed under 180 px.
class FeaturedCarousel extends StatelessWidget {
  const FeaturedCarousel({
    required this.items,
    required this.picture,
    required this.onOpen,
    this.bleed = true,
    super.key,
  });
  final List<InventoryItem> items;
  final Widget Function(String) picture;
  final ValueChanged<InventoryItem> onOpen;

  /// Run to the screen edges (phones).
  final bool bleed;

  @override
  Widget build(BuildContext context) {
    final carousel = CarouselView.weighted(
      flexWeights: const [7, 2],
      itemSnapping: true,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      onTap: (i) => onOpen(items[i]),
      children: [for (final item in items) _FeaturedItem(item: item, picture: picture)],
    );
    return bleed ? _Bleed(height: 230, by: 12, child: carousel) : SizedBox(height: 230, child: carousel);
  }
}

class _FeaturedItem extends StatelessWidget {
  const _FeaturedItem({required this.item, required this.picture});
  final InventoryItem item;
  final Widget Function(String) picture;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(item.category);
    final (fill, ink) = AppColors.category(style.tone);
    final photo = item.imageUrl.isNotEmpty;
    return Semantics(
      button: true,
      label: '${item.name}, ${item.category}, ${item.available} unit siap',
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo) ...[
            picture(item.imageUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xD90A101B)],
                  stops: [.3, 1],
                ),
              ),
            ),
          ] else
            ColoredBox(
              color: fill,
              child: Align(
                alignment: const Alignment(.7, -.6),
                child: ShapeIcon(
                  icon: style.icon,
                  shape: style.shape,
                  size: 132,
                  iconScale: .4,
                  fill: ink.withValues(alpha: .12),
                  foreground: ink.withValues(alpha: .6),
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth < 180
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${item.category} · ${item.available} siap',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(
                            color: photo ? context.colors.primaryFixed : context.colors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleLarge?.copyWith(color: photo ? Colors.white : ink, height: 1.2),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
