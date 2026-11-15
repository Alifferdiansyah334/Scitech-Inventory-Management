import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/shapes.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../catalog/item_row.dart';

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// 'Jum, 7 Nov 2026' style date used on the request and receipt.
String longDate(DateTime value) =>
    '${_days[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]} ${value.year}';

/// Content width used by the request form and its success receipt.
const requestMaxWidth = 640.0;

Widget centered(Widget child) => Center(
  heightFactor: 1,
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: requestMaxWidth),
    child: child,
  ),
);

/// The item being requested in the AgroLens ArticleRow recipe: white card
/// radius 24 with padding 10, the picture 84 (radius 16), the category in
/// primary, the name and what is ready.
class RequestItemSummary extends StatelessWidget {
  const RequestItemSummary({required this.item, this.picture, super.key});
  final InventoryItem item;

  /// Renders the item photo; without it the category block stands in.
  final Widget Function(String)? picture;

  @override
  Widget build(BuildContext context) {
    final thumb = picture != null && item.imageUrl.isNotEmpty
        ? ItemThumb(item: item, picture: picture!, size: 84)
        : ExcludeSemantics(child: CategoryBlock(category: item.category, size: 84));
    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          thumb,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category, style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
                const SizedBox(height: 2),
                Text(item.name, style: context.text.titleMedium?.copyWith(height: 1.3)),
                const SizedBox(height: 6),
                Text(
                  '${item.available} unit siap · ID ${shortId(item.id)}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// Bottom bar of the editor (article_editor.dart): SafeArea, padding
/// 16/8/16/12, the request error when any, and the full-width primary
/// button at least 56 tall with the check in a cookie shape.
class RequestSubmit extends StatelessWidget {
  const RequestSubmit({required this.busy, required this.error, required this.onSubmit, super.key});
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: centered(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                    child: Row(
                      children: [
                        ShapeIcon(
                          icon: Icons.priority_high_rounded,
                          shape: ExpressiveShape.burst,
                          size: 32,
                          fill: scheme.error,
                          foreground: scheme.onError,
                          iconScale: .5,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              error!,
                              style: context.text.labelLarge?.copyWith(color: scheme.onErrorContainer),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: busy ? null : onSubmit,
                icon: busy
                    ? ExpressiveLoadingIndicator(size: 24, color: AppColors.onDisabled)
                    : ShapeIcon(
                        icon: Icons.check_rounded,
                        shape: ExpressiveShape.cookie9,
                        size: 28,
                        fill: scheme.onPrimary,
                        foreground: scheme.primary,
                        iconScale: .6,
                      ),
                label: Text(busy ? 'Mengirim pengajuan...' : 'Ajukan peminjaman', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon and muted note (AgroLens result footer).
class RequestNote extends StatelessWidget {
  const RequestNote(this.text, {this.icon = Icons.info_outline_rounded, super.key});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ),
    ],
  );
}
