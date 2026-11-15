part of 'loan_details.dart';

/// One label/value row (AgroLens result `_NumberedRow`): a 30 px shaped
/// badge (or [leading]), the label in muted text and the value below it.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.label,
    required this.value,
    this.icon,
    this.shape = ExpressiveShape.cookie9,
    this.detail,
    this.leading,
  });
  final String label, value;
  final String? detail;
  final IconData? icon;
  final ExpressiveShape shape;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                ShapeIcon(
                  icon: icon ?? Icons.info_outline_rounded,
                  shape: shape,
                  size: 30,
                  fill: AppColors.secondary,
                  foreground: AppColors.onSecondary,
                  iconScale: .55,
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.labelMedium?.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: text.bodyLarge?.copyWith(color: AppColors.ink, height: 1.45, fontFeatures: tabular),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: text.bodySmall?.copyWith(color: AppColors.muted, fontFeatures: tabular),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stock of the loaned item: ready now and, for a request, what remains
/// after approval, as text plus wavy bars.
class _StockImpact extends StatelessWidget {
  const _StockImpact({required this.loan, required this.item, required this.color});
  final Loan loan;
  final InventoryItem item;
  final Color color;

  Widget _column(String label, int ready, String value, {Color? color}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
      ),
      const SizedBox(height: 10),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: WavyLinearProgress(
          value: item.total <= 0 ? 0 : (ready < 0 ? 0 : ready) / item.total,
          color: color ?? AppColors.primary,
          trackColor: AppColors.high,
          semanticsLabel: label,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        value,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFeatures: tabular, color: color),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final pending = loan.status == 'pending';
    final after = item.available - loan.quantity;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _column(
              pending ? 'Stok siap sekarang' : 'Stok saat ini',
              item.available,
              '${item.available} dari ${item.total} siap',
            ),
          ),
          if (pending) ...[
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: _column(
                'Setelah disetujui',
                after,
                after < 0 ? 'Kurang ${-after} unit' : '$after dari ${item.total}',
                color: after <= 0 ? AppColors.deadline : AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
