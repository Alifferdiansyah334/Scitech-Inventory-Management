import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// Item in the AgroLens ArticleRow recipe (widgets/domain.dart): white card
/// radius 24 with padding 10, an 84 picture with radius 16, then the
/// category (labelMedium, primary), the name (titleMedium, two lines) and
/// the metadata (bodySmall). [SurfaceCard] owns the press spring, morph and
/// activation haptic. Large text lets the name wrap in full.
class ItemRow extends StatelessWidget {
  const ItemRow({required this.item, required this.picture, required this.onTap, this.meta, this.trailing, super.key});
  final InventoryItem item;
  final Widget Function(String) picture;
  final VoidCallback? onTap;

  /// Muted line under the name; defaults to the ready/total units.
  final String? meta;

  /// Optional widget at the end (status pill, action button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(16) > 20;
    final ready = item.enabled
        ? (item.available > 0 ? '${item.available}/${item.total} unit siap' : 'Stok habis')
        : 'Tidak dipinjamkan';
    final dotColor = !item.enabled
        ? context.colors.error
        : item.available > 0
        ? AppColors.ok
        : AppColors.deadline;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(item.category, style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
            ),
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                child: Text(
                  shortId(item.id),
                  style: context.text.labelSmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: context.colors.onSurfaceVariant,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          item.name,
          maxLines: large ? null : 2,
          overflow: large ? null : TextOverflow.ellipsis,
          style: context.text.titleMedium?.copyWith(height: 1.3),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                meta ?? ready,
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, fontFeatures: tabular),
              ),
            ),
          ],
        ),
        if (trailing != null) ...[
          const SizedBox(height: 8),
          Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
        ],
      ],
    );
    return SurfaceCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, box) {
          final thumbnail = ItemThumb(item: item, picture: picture, size: 84);
          // Too narrow for the name beside the picture: stack them.
          if (box.maxWidth < 240) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [thumbnail, const SizedBox(height: 10), details],
            );
          }
          return Row(
            children: [
              thumbnail,
              const SizedBox(width: 14),
              Expanded(child: details),
              const SizedBox(width: 6),
            ],
          );
        },
      ),
    );
  }
}

/// Square item picture: the photo with radius 16, or the category's shape
/// and icon on its tint. Inside a [PressSpring] the shape morphs with it.
class ItemThumb extends StatelessWidget {
  const ItemThumb({required this.item, required this.picture, this.size = 84, super.key});
  final InventoryItem item;
  final Widget Function(String) picture;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl.isNotEmpty) {
      return ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.square(dimension: size, child: picture(item.imageUrl)),
        ),
      );
    }
    return ExcludeSemantics(
      child: CategoryBlock(category: item.category, size: size),
    );
  }
}

/// The category tint with its shape and icon, radius 16: the stand-in for
/// an item without a photo.
class CategoryBlock extends StatelessWidget {
  const CategoryBlock({required this.category, this.size = 84, super.key});
  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category);
    final (fill, ink) = AppColors.category(style.tone);
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: ShapeIcon(icon: style.icon, shape: style.shape, size: size * .66, fill: ink, foreground: fill),
        ),
      ),
    );
  }
}
