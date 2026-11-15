part of 'item_details.dart';

/// Verdict card (header_verdict.dart): status pill, name, category in
/// italics and the ID with the total on the left; the ready units counting
/// up inside a wavy ring 96 on the right. Only very large text on a narrow
/// card moves the ring under the text.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final status = itemStatus(item);
    final share = item.total == 0 ? 0.0 : item.available / item.total;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusPill(status.label, tone: status.tone),
        const SizedBox(height: 12),
        Semantics(header: true, child: Text(item.name, style: context.text.headlineSmall?.copyWith(height: 1.15))),
        const SizedBox(height: 4),
        Text(
          item.category,
          style: context.text.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  'ID ${shortId(item.id)}',
                  style: context.text.labelMedium?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: context.colors.onSurfaceVariant,
                    fontFeatures: tabular,
                  ),
                ),
              ),
            ),
            Text(
              '${item.total} unit total',
              style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant, fontFeatures: tabular),
            ),
          ],
        ),
      ],
    );
    final ring = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: share),
      duration: reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => WavyRingProgress(
        value: v,
        size: 96,
        semanticsLabel: '${item.available} dari ${item.total} unit siap',
        child: child!,
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountUp(item.available, style: context.text.titleLarge?.copyWith(height: 1, fontFeatures: tabular)),
                Text('siap', style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: context.colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: context.colors.outlineVariant.withValues(alpha: .6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          child: LayoutBuilder(
            builder: (context, box) {
              final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final stacked = scale >= 1.8 && box.maxWidth < 420;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [identity, const SizedBox(height: 16), ring],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 12),
                  ring,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
