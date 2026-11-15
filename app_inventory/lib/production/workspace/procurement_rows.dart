part of 'procurement.dart';

/// One purchase as a 'Kelola' row: the item's category shape, name,
/// supplier and quantity × cost, the status pill and total; open orders end
/// with confirm receipt and cancel.
extension _ProcurementRows on _ProcurementSectionState {
  StatusPill _status(Procurement record) => StatusPill(
    _statuses.where((s) => s.$1 == record.status).firstOrNull?.$2 ?? record.status,
    tone: switch (record.status) {
      'ordered' => Tone.waiting,
      'received' => Tone.ok,
      _ => Tone.neutral,
    },
    dense: true,
  );

  Widget _row(Procurement record, String category) {
    final locked = actions.locked;
    final open = record.status == 'ordered';
    return ManageRow(
      leading: ShapeIcon.category(category, size: 60),
      title: record.name,
      meta: '${record.supplier} · ${record.quantity} × ${rupiah(record.cost)}',
      pills: [
        _status(record),
        Text(
          rupiah(record.cost * record.quantity),
          style: context.text.titleSmall?.copyWith(fontFeatures: tabular, color: AppColors.ink),
        ),
      ],
      actions: [
        if (open) ...[
          ShapeAction(
            icon: Icons.task_alt_rounded,
            tooltip: 'Konfirmasi diterima',
            shape: ExpressiveShape.flower8,
            fill: AppColors.okContainer,
            foreground: AppColors.onOkContainer,
            onPressed: locked ? null : () => setStatus(record, 'received'),
          ),
          ShapeAction(
            icon: Icons.cancel_outlined,
            tooltip: 'Batalkan',
            shape: ExpressiveShape.burst,
            danger: true,
            onPressed: locked ? null : () => setStatus(record, 'cancelled'),
          ),
        ],
      ],
    );
  }
}
