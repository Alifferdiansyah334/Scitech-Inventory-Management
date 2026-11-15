part of 'catalog_parts.dart';

/// Empty catalogue in the AgroLens history_empty recipe: a flower shape 112
/// that can be tugged on a spring, the title, a short reason and the one
/// next action (with an optional second one).
class CatalogEmpty extends StatelessWidget {
  const CatalogEmpty({
    required this.title,
    required this.message,
    this.icon = Icons.search_rounded,
    this.action,
    this.secondaryAction,
    super.key,
  });
  final String title, message;
  final IconData icon;
  final Widget? action, secondaryAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
    child: Column(
      children: [
        ExcludeSemantics(
          child: SpringDraggable(
            reach: 110,
            child: PressSpring(
              squash: .12,
              child: ShapeIcon(
                icon: icon,
                shape: ExpressiveShape.flower8,
                size: 112,
                fill: context.colors.secondaryContainer,
                foreground: context.colors.onSecondaryContainer,
                iconScale: .4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
        if (secondaryAction != null) ...[const SizedBox(height: 8), secondaryAction!],
      ],
    ),
  );
}

/// Card shown under the items while a failed catalog reloads: the expressive
/// loading shape (still when motion is reduced) and the status in words.
class CatalogReloadRow extends StatelessWidget {
  const CatalogReloadRow({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        const ExpressiveLoadingIndicator(size: 44, semanticsLabel: 'Memuat ulang katalog'),
        const SizedBox(width: 14),
        Expanded(
          child: Semantics(liveRegion: true, child: Text('Memuat ulang katalog…', style: context.text.titleSmall)),
        ),
      ],
    ),
  );
}
