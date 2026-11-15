part of 'item_details.dart';

/// Section title in the result body (titleLarge, 12 below).
class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(header: true, child: Text(text, style: context.text.titleLarge)),
  );
}

/// "Siap dipinjam   3/4" over a wavy bar (AgroLens 'Kemungkinan lain' row).
class _StockBar extends StatelessWidget {
  const _StockBar({required this.label, required this.value, required this.total, required this.color});
  final String label;
  final int value, total;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      label: '$label $value dari $total unit',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.text.bodyLarge)),
              Text('$value/$total', style: context.text.labelLarge?.copyWith(fontFeatures: tabular)),
            ],
          ),
          const SizedBox(height: 4),
          WavyLinearProgress(value: total == 0 ? 0 : value / total, color: color),
        ],
      ),
    ),
  );
}

/// Small icon and note at the end of the page (AgroLens result footer).
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: context.text.bodySmall?.copyWith(color: color)),
      ),
    ],
  );
}

/// AgroLens result action bar: surface with a hairline on top, padding
/// 16/12, the square outlined button 52 (copy the item ID) and the primary
/// action 52 tall filling the rest.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.item, required this.onBorrow});
  final InventoryItem item;
  final VoidCallback? onBorrow;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shortId(item.id)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID ${shortId(item.id)} disalin')));
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border(top: BorderSide(color: context.colors.outlineVariant.withValues(alpha: .5))),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Salin ID barang',
                  onPressed: () => _copy(context),
                  style: IconButton.styleFrom(fixedSize: const Size.square(52)),
                  icon: const Icon(Icons.copy_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: FilledButton.icon(
                      onPressed: onBorrow,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Ajukan peminjaman', textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
