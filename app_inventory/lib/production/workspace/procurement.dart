import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/controls.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../forms.dart';
import 'actions.dart';
import 'admin_fab.dart';
import 'admin_rows.dart';
import 'chrome.dart';

part 'procurement_rows.dart';

/// Status key, label, chip icon and shape.
const _statuses = <(String, String, IconData, ExpressiveShape)>[
  ('ordered', 'Menunggu diterima', Icons.schedule_rounded, ExpressiveShape.sunny8),
  ('received', 'Sudah diterima', Icons.check_rounded, ExpressiveShape.flower8),
  ('cancelled', 'Dibatalkan', Icons.block_rounded, ExpressiveShape.cookie9),
];

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

/// Admin 'Pengadaan' after AgroLens' 'Kelola artikel' (search and status
/// chips on top): one white row per purchase with its status pill and, while
/// open, receive (flower8) and cancel (burst) actions. Phones add purchases
/// with the FAB, wide layouts with the pill beside the search.
class ProcurementSection extends StatefulWidget {
  const ProcurementSection({required this.actions, super.key});
  final WorkspaceActions actions;

  @override
  State<ProcurementSection> createState() => _ProcurementSectionState();
}

class _ProcurementSectionState extends State<ProcurementSection> {
  final query = TextEditingController();
  String search = '';

  /// Status filter key; null shows every record.
  String? status;

  WorkspaceActions get actions => widget.actions;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  /// Sheet of inventory items as shaped link rows; resolves to the choice.
  Future<InventoryItem?> _pickItem() => showModalBottomSheet<InventoryItem>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    sheetAnimationStyle: sheetAnimation(context),
    constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * .85),
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Semantics(
                header: true,
                child: Text('Pilih barang', style: Theme.of(sheet).textTheme.headlineSmall),
              ),
            ),
            LinkGroup(
              children: [
                for (final item in actions.app.items)
                  LinkTile(
                    icon: categoryStyle(item.category).icon,
                    shape: categoryStyle(item.category).shape,
                    title: item.name,
                    subtitle: [if (item.category.isNotEmpty) item.category, '${item.total} unit'].join(' · '),
                    onTap: () => Navigator.pop(sheet, item),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> add() async {
    final app = actions.app;
    final selected = await _pickItem();
    if (selected == null || !mounted) return;
    final values = await promptForm(context, 'Pengadaan ${selected.name}', [
      const InputSpec('quantity', 'Jumlah unit', initial: '1', numeric: true, max: 6),
      const InputSpec('supplier', 'Pemasok', min: 2, max: 160),
      const InputSpec('cost', 'Biaya per unit (Rp)', initial: '0', decimal: true, max: 16),
    ], icon: Icons.local_shipping_outlined);
    if (values == null || !mounted) return;
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
      celebrate: true,
    );
  }

  Future<void> setStatus(Procurement record, String status) async {
    final receiving = status == 'received';
    if (await confirmAction(
      context,
      'Konfirmasi pengadaan?',
      receiving ? 'Stok barang akan bertambah ${record.quantity} unit.' : 'Pesanan ini akan dibatalkan.',
      icon: receiving ? Icons.task_alt_rounded : Icons.cancel_outlined,
      danger: !receiving,
      confirm: receiving ? 'Tandai diterima' : 'Batalkan pesanan',
    )) {
      await actions.perform(
        () => actions.app
            .mutate('api/admin/procurements', method: 'PATCH', data: {'id': record.id, 'status': status})
            .then((_) {}),
        celebrate: receiving,
      );
    }
  }

  void _clear() {
    query.clear();
    setState(() {
      search = '';
      status = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final records = app.procurements;
    final ordered = records.where((p) => p.status == 'ordered').length;
    final needle = search.trim().toLowerCase();
    final rows = records
        .where(
          (p) => (status == null || p.status == status) && '${p.name} ${p.supplier}'.toLowerCase().contains(needle),
        )
        .toList();
    final wide = chromeWide(context);
    final onAdd = actions.locked || app.items.isEmpty ? null : add;
    // Procurement records carry the item name only; the category (for the
    // shape) comes from the matching inventory item.
    final categories = {for (final item in app.items) item.name: item.category};
    return SectionLayout(
      title: 'Pengadaan',
      extra: sectionSummary(context, '$ordered pesanan menunggu diterima · ${records.length} total'),
      children: [
        AdminListHeader(
          search: ExpressiveSearchBar(
            controller: query,
            hintText: 'Cari barang atau pemasok',
            onChanged: (value) => setState(() => search = value),
            onClear: () {
              query.clear();
              setState(() => search = '');
            },
          ),
          chips: records.isEmpty
              ? null
              : ChipStrip(
                  children: [
                    ExpressiveFilterChip(
                      label: 'Semua ${records.length}',
                      icon: Icons.apps_rounded,
                      selected: status == null,
                      onSelected: () => setState(() => status = null),
                    ),
                    for (final (key, label, icon, shape) in _statuses)
                      ExpressiveFilterChip(
                        label: '$label ${records.where((p) => p.status == key).length}',
                        icon: icon,
                        shape: shape,
                        selected: status == key,
                        onSelected: () => setState(() => status = status == key ? null : key),
                      ),
                  ],
                ),
          caption: rows.length == records.length
              ? 'Semua pengadaan'
              : '${rows.length} dari ${records.length} pengadaan',
          action: wide
              ? PillAction(
                  label: 'Pengadaan baru',
                  icon: Icons.add_rounded,
                  shape: ExpressiveShape.sunny8,
                  onPressed: onAdd,
                )
              : null,
        ),
        if (records.isEmpty)
          AdminEmpty(
            title: 'Belum ada pengadaan',
            message: app.items.isEmpty
                ? 'Belum ada pengadaan barang. Tambahkan barang di menu Barang terlebih dahulu.'
                : 'Belum ada pengadaan barang. Catat pembelian pertama.',
            icon: Icons.local_shipping_outlined,
            action: app.items.isEmpty
                ? null
                : FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Catat pengadaan'),
                  ),
          )
        else if (rows.isEmpty)
          AdminEmpty(
            title: 'Tidak ada yang cocok',
            message: 'Tidak ada pengadaan yang cocok dengan pencarian atau status ini.',
            icon: Icons.search_off_rounded,
            action: OutlinedButton(onPressed: _clear, child: const Text('Hapus filter')),
          )
        else
          AdminGrid(
            children: [
              for (final record in rows)
                KeyedSubtree(key: ValueKey(record.id), child: _row(record, categories[record.name] ?? '')),
            ],
          ),
        if (!wide) ...[
          AdminFab(label: 'Pengadaan baru', icon: Icons.local_shipping_outlined, onPressed: onAdd),
          const SizedBox(height: AdminFab.clearance),
        ],
      ],
    );
  }
}
