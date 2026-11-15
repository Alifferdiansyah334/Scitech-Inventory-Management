part of 'borrower_home.dart';

/// A category on the shelf: its items and the units ready to borrow.
class _Category {
  _Category(this.name, this.items) : ready = items.where((i) => i.enabled).fold(0, (sum, i) => sum + i.available);
  final String name;
  final List<InventoryItem> items;
  final int ready;

  /// First item with a photo, for the guide-style card.
  InventoryItem? get cover => items.where((i) => i.imageUrl.isNotEmpty).firstOrNull;
}

/// AgroLens SectionHeader: padding 20/top/8/10, the title (titleLarge)
/// and the text action in one row; a long title wraps beside the action.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.action, this.onAction, this.top = 24});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, top, 8, 10),
    child: LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: context.text.titleLarge)),
          ),
          // The title keeps the row; at large text the action wraps
          // within at most 45% instead of pushing past the edge.
          if (action != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * .45),
              child: TextButton(
                onPressed: onAction,
                child: Text(action!, textAlign: TextAlign.end),
              ),
            ),
        ],
      ),
    ),
  );
}

/// White card radius 24 with the AgroLens press spring.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.child, required this.onTap, this.color, this.radius = 24});
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return Semantics(
      container: true,
      button: true,
      child: PressSpring(
        scale: .97,
        child: Material(
          color: color ?? AppColors.card,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: tactileTap(onTap), customBorder: shape, child: child),
        ),
      ),
    );
  }
}

/// Newest own loan (AgroLens _LastScan, content_cards.dart): radius 24,
/// padding 12, the item in its category shape 64, the name (titleMedium,
/// one line), units and due date (bodySmall) and the status pill.
class _LastLoan extends StatelessWidget {
  const _LastLoan({required this.loan, required this.item, required this.picture, required this.onTap});
  final Loan loan;
  final InventoryItem? item;
  final Widget Function(String) picture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(item?.category ?? '');
    final photo = item?.imageUrl ?? '';
    return _Tappable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 64,
              child: photo.isEmpty
                  ? ShapeIcon.category(item?.category ?? '', size: 64)
                  : ShapeClip(shape: style.shape, child: picture(photo)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.name,
                    maxLines: MediaQuery.textScalerOf(context).scale(16) > 20 ? null : 1,
                    overflow: MediaQuery.textScalerOf(context).scale(16) > 20 ? null : TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${loan.quantity} unit · kembali ${dayDate(loan.dueDate)}',
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  StatusPill(loan.label, tone: loanTone(loan.status, late: loan.late), dense: true),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Category card (AgroLens _GuideCard): 236 wide, at least 196 tall,
/// radius 28, the first item photo under a dark fade or the category tint
/// with its shape; a white 'Kategori' pill on top and the name (titleMedium)
/// with item and ready counts at the bottom.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.picture, required this.onTap});
  final _Category category;
  final Widget Function(String) picture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category.name);
    final (tint, onTint) = AppColors.category(style.tone);
    final cover = category.cover;
    final ink = cover == null ? onTint : Colors.white;
    return SizedBox(
      width: MediaQuery.textScalerOf(context).scale(16) > 20 ? 280 : 236,
      child: TiltOnTouch(
        child: _Tappable(
          onTap: onTap,
          radius: 28,
          color: cover == null ? tint : AppColors.high,
          child: Stack(
            children: [
              if (cover != null) ...[
                Positioned.fill(child: picture(cover.imageUrl)),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC0A101B)],
                        stops: [.35, 1],
                      ),
                    ),
                  ),
                ),
              ] else
                Positioned(
                  right: -26,
                  top: 4,
                  child: ShapeIcon(
                    icon: style.icon,
                    shape: style.shape,
                    size: 150,
                    fill: onTint.withValues(alpha: .1),
                    foreground: onTint.withValues(alpha: .55),
                    iconScale: .4,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: const ShapeDecoration(color: Colors.white, shape: StadiumBorder()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text('Kategori', style: context.text.labelMedium?.copyWith(color: context.palette.ink)),
                      ),
                    ),
                    const SizedBox(height: 106),
                    Text(category.name, style: context.text.titleMedium?.copyWith(color: ink, height: 1.25)),
                    const SizedBox(height: 2),
                    Text(
                      '${category.items.length} barang · ${category.ready} siap',
                      style: context.text.labelMedium?.copyWith(
                        color: ink.withValues(alpha: .85),
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
