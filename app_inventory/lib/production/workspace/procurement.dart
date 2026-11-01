import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../forms.dart';
import 'actions.dart';
import 'chrome.dart';

const _statusLabels = {
  'ordered': 'Menunggu diterima',
  'received': 'Sudah diterima',
  'cancelled': 'Dibatalkan',
};

/// Rp1.250.000
String rupiah(double value) {
  final digits = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final left = digits.length - i;
    buffer.write(digits[i]);
    if (left > 1 && left % 3 == 1 && digits[i] != '-') buffer.write('.');
  }
  return 'Rp$buffer';
}

/// Admin 'Pengadaan': record purchases and confirm receipt into stock.
class ProcurementSection extends StatelessWidget {
  const ProcurementSection({required this.actions, super.key});
  final WorkspaceActions actions;

  Future<void> add(BuildContext context) async {
    final app = actions.app;
    final selected = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih barang'),
        children: [
          for (final item in app.items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: Text(item.name),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    final values = await promptForm(context, 'Pengadaan ${selected.name}', [
      const InputSpec(
        'quantity',
        'Jumlah unit',
        initial: '1',
        numeric: true,
        max: 6,
      ),
      const InputSpec('supplier', 'Pemasok', min: 2, max: 160),
      const InputSpec(
        'cost',
        'Biaya per unit (Rp)',
        initial: '0',
        decimal: true,
        max: 16,
      ),
    ]);
    if (values == null || !context.mounted) return;
    await actions.perform(
      () => app
          .mutate(
            'api/admin/procurements',
            data: {
              'item_id': selected.id,
              'quantity': int.parse(values['quantity']!),
              'supplier': values['supplier'],
              'unit_cost': double.parse(values['cost']!),
            },
          )
          .then((_) {}),
    );
  }

  Future<void> setStatus(
    BuildContext context,
    Procurement record,
    String status,
  ) async {
    if (await confirmAction(
      context,
      'Konfirmasi pengadaan?',
      status == 'received'
          ? 'Stok barang akan bertambah ${record.quantity} unit.'
          : 'Pesanan ini akan dibatalkan.',
    )) {
      await actions.perform(
        () => actions.app
            .mutate(
              'api/admin/procurements',
              method: 'PATCH',
              data: {'id': record.id, 'status': status},
            )
            .then((_) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final ordered = app.procurements.where((p) => p.status == 'ordered');
    return SectionLayout(
      title: 'Pengadaan',
      extra: Text(
        '${ordered.length} pesanan menunggu diterima · ${app.procurements.length} total',
        style: const TextStyle(color: AppColors.navyMuted, fontSize: 14),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: actions.locked || app.items.isEmpty
                ? null
                : () => add(context),
            icon: const Icon(Icons.add),
            label: const Text('Tambah pengadaan'),
          ),
        ),
        const SizedBox(height: 18),
        if (app.procurements.isEmpty)
          const StateMessage(
            title: 'Belum ada pengadaan',
            message: 'Belum ada pengadaan barang.',
            icon: Icons.local_shipping_outlined,
          ),
        for (var i = 0; i < app.procurements.length; i++)
          Padding(
            key: ValueKey(app.procurements[i].id),
            padding: const EdgeInsets.only(bottom: 12),
            child: SpringReveal(
              index: i,
              child: _card(context, app.procurements[i]),
            ),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, Procurement record) => SurfaceCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconTile(Icons.local_shipping_outlined, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    '${record.quantity} unit · ${record.supplier}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusPill(
                    _statusLabels[record.status] ?? record.status,
                    tone: switch (record.status) {
                      'ordered' => Tone.waiting,
                      'received' => Tone.ok,
                      _ => Tone.neutral,
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Biaya per unit: ${rupiah(record.cost)} · total ${rupiah(record.cost * record.quantity)}',
          style: const TextStyle(fontSize: 14),
        ),
        if (record.status == 'ordered') ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              tonalAction(
                'Konfirmasi diterima',
                Icons.task_alt,
                actions.locked
                    ? null
                    : () => setStatus(context, record, 'received'),
              ),
              tonalAction(
                'Batalkan',
                Icons.cancel_outlined,
                actions.locked
                    ? null
                    : () => setStatus(context, record, 'cancelled'),
                danger: true,
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
