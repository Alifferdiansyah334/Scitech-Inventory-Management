import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'category_icons.dart';

/// Item photo (real image or navySoft category placeholder) with the
/// availability pill and the item's asset tag.
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    required this.item,
    required this.picture,
    this.height,
    this.width,
    this.iconSize = 40,
    this.tags = true,
    super.key,
  });
  final InventoryItem item;
  final Widget Function(String) picture;
  final double? height, width;
  final double iconSize;
  final bool tags;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: height,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.imageUrl.isEmpty)
            ColoredBox(
              color: AppColors.navySoft,
              child: Icon(
                categoryIcon(item.category),
                color: AppColors.navy,
                size: iconSize,
              ),
            )
          else
            picture(item.imageUrl),
          if (tags) ...[
            Positioned(top: 8, left: 8, child: AvailabilityPill(item: item)),
            Positioned(bottom: 8, left: 8, child: AssetTag(item.id)),
          ],
        ],
      ),
    ),
  );
}

/// '● 2/3' — available of total units, green dot when it can be borrowed.
class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({required this.item, super.key});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) => Semantics(
    label: item.canBorrow
        ? '${item.available} dari ${item.total} unit tersedia'
        : 'Tidak tersedia',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.canBorrow ? AppColors.ok : AppColors.control,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${item.available}/${item.total}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: item.canBorrow ? AppColors.ok : AppColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Catalog card in grid or list form: photo, category, name, 'Lihat detail'
/// and a round quick-request button for borrowable items.
class CatalogItemCard extends StatelessWidget {
  const CatalogItemCard({
    required this.item,
    required this.picture,
    required this.list,
    required this.onDetails,
    required this.onBorrow,
    super.key,
  });
  final InventoryItem item;
  final Widget Function(String) picture;
  final bool list;
  final VoidCallback onDetails, onBorrow;

  @override
  Widget build(BuildContext context) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 40,
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: onDetails,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Lihat detail'),
                  ),
                ),
              ),
            ),
            if (item.canBorrow)
              PressSpring(
                child: IconButton.filled(
                  tooltip: 'Ajukan cepat',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    fixedSize: const Size(44, 44),
                  ),
                  onPressed: onBorrow,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
          ],
        ),
      ],
    );
    return SurfaceCard(
      padding: const EdgeInsets.all(8),
      onTap: onDetails,
      child: list
          ? Row(
              children: [
                ItemPhoto(
                  item: item,
                  picture: picture,
                  width: 112,
                  height: 112,
                  iconSize: 36,
                ),
                const SizedBox(width: 12),
                Expanded(child: info),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ItemPhoto(item: item, picture: picture, height: 128),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: info,
                ),
              ],
            ),
    );
  }
}
