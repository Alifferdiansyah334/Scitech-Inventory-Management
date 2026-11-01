import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../catalog/category_icons.dart';
import '../forms.dart';
import '../item_editor.dart';
import 'actions.dart';
import 'chrome.dart';

/// Admin 'Barang': search, add, edit and delete inventory items.
class AdminInventory extends StatefulWidget {
  const AdminInventory({required this.actions, super.key});
  final WorkspaceActions actions;

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  String search = '';

  WorkspaceActions get a => widget.actions;

  Future<void> remove(InventoryItem item) async {
    if (await confirmAction(
      context,
      'Hapus barang?',
      '${item.name} akan dihapus. Barang yang mempunyai riwayat peminjaman mungkin tidak dapat dihapus.',
    )) {
      await a.perform(
        () =>
            a.app.mutate('api/items/${item.id}', method: 'DELETE').then((_) {}),
      );
    }
  }

  void edit([InventoryItem? item]) => showDialog<bool>(
    context: context,
    builder: (_) => ItemEditor(state: a.app, item: item),
  );

  @override
  Widget build(BuildContext context) {
    final app = a.app;
    final rows = app.items
        .where(
          (item) => '${item.name} ${item.category}'.toLowerCase().contains(
            search.toLowerCase(),
          ),
        )
        .toList();
    final units = app.items.fold<int>(0, (sum, item) => sum + item.available);
    return SectionLayout(
      title: 'Barang',
      extra: Text(
        '${app.items.length} jenis · $units unit tersedia',
        style: const TextStyle(color: AppColors.navyMuted, fontSize: 14),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau kategori',
                  prefixIcon: Icon(Icons.search),
                  fillColor: AppColors.surface,
                ),
                onChanged: (value) => setState(() => search = value),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: a.locked ? null : () => edit(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (rows.isEmpty)
          StateMessage(
            title: search.isEmpty
                ? 'Inventaris masih kosong'
                : 'Tidak ada yang cocok',
            message: search.isEmpty
                ? 'Belum ada barang dalam inventaris.'
                : 'Tidak ada barang yang cocok.',
            icon: search.isEmpty
                ? Icons.inventory_2_outlined
                : Icons.search_off_rounded,
          ),
        for (var i = 0; i < rows.length; i++)
          Padding(
            key: ValueKey(rows[i].id),
            padding: const EdgeInsets.only(bottom: 12),
            child: SpringReveal(index: i, child: _itemCard(rows[i])),
          ),
      ],
    );
  }

  Widget _itemCard(InventoryItem item) => SurfaceCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.control),
              child: SizedBox(
                width: 76,
                height: 76,
                child: a.picture(
                  item.imageUrl,
                  icon: categoryIcon(item.category),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssetTag(item.id, dark: true),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    item.category,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusPill(
                        '${item.available} dari ${item.total} unit tersedia',
                        tone: item.available > 0 ? Tone.ok : Tone.waiting,
                      ),
                      if (!item.enabled)
                        const StatusPill(
                          'Peminjaman dinonaktifkan',
                          tone: Tone.bad,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (item.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              item.description,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            tonalAction(
              'Ubah',
              Icons.edit_outlined,
              a.locked ? null : () => edit(item),
            ),
            tonalAction(
              'Hapus',
              Icons.delete_outline,
              a.locked || item.reserved > 0 ? null : () => remove(item),
              danger: true,
            ),
          ],
        ),
      ],
    ),
  );
}
