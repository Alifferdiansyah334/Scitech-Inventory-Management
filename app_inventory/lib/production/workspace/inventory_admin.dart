import 'package:flutter/material.dart';
import '../../ui/tokens.dart';
import 'package:flutter/services.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/controls.dart';
import '../../ui/shapes.dart';
import '../forms.dart';
import '../item_editor.dart';
import 'actions.dart';
import 'admin_fab.dart';
import 'admin_rows.dart';
import 'chrome.dart';

/// Admin 'Barang' after AgroLens' 'Kelola artikel' (with the library's
/// search and category chips on top): one white row per item with its
/// shaped picture, edit (cookie9) and delete (burst) actions; tapping the
/// row edits too. Phones add items with the 'Barang baru' FAB, wide
/// layouts with the pill beside the search.
class AdminInventory extends StatefulWidget {
  const AdminInventory({required this.actions, super.key});
  final WorkspaceActions actions;

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  final query = TextEditingController();
  String search = '';

  /// Selected category; null shows every item.
  String? category;

  WorkspaceActions get a => widget.actions;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> remove(InventoryItem item) async {
    HapticFeedback.mediumImpact();
    if (await confirmAction(
      context,
      'Hapus barang?',
      '"${item.name}" akan dihapus. Barang yang mempunyai riwayat peminjaman mungkin tidak dapat dihapus.',
      icon: Icons.delete_outline_rounded,
      danger: true,
      confirm: 'Hapus',
    )) {
      await a.perform(() => a.app.mutate('api/items/${item.id}', method: 'DELETE').then((_) {}));
    }
  }

  void edit([InventoryItem? item]) => openItemEditor(context, a.app, item);

  void _clear() {
    query.clear();
    setState(() {
      search = '';
      category = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = a.app;
    final categories = {
      for (final item in app.items)
        if (item.category.trim().isNotEmpty) item.category.trim(),
    }.toList()..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
    final active = categories.contains(category) ? category : null;
    final needle = search.trim().toLowerCase();
    final rows = app.items
        .where(
          (item) =>
              (active == null || item.category.trim() == active) &&
              '${item.name} ${item.category}'.toLowerCase().contains(needle),
        )
        .toList();
    final units = app.items.fold<int>(0, (sum, item) => sum + item.available);
    final filtered = needle.isNotEmpty || active != null;
    final wide = chromeWide(context);
    final onAdd = a.locked ? null : () => edit();
    return SectionLayout(
      title: 'Barang',
      extra: sectionSummary(context, '${app.items.length} jenis · $units unit tersedia'),
      children: [
        AdminListHeader(
          search: ExpressiveSearchBar(
            controller: query,
            hintText: 'Cari nama atau kategori',
            onChanged: (value) => setState(() => search = value),
            onClear: () {
              query.clear();
              setState(() => search = '');
            },
          ),
          chips: categories.length < 2
              ? null
              : ChipStrip(
                  children: [
                    ExpressiveFilterChip(
                      label: 'Semua',
                      icon: Icons.apps_rounded,
                      selected: active == null,
                      onSelected: () => setState(() => category = null),
                    ),
                    for (final c in categories)
                      ExpressiveFilterChip(
                        label: c,
                        icon: categoryStyle(c).icon,
                        shape: categoryStyle(c).shape,
                        selected: active == c,
                        onSelected: () => setState(() => category = active == c ? null : c),
                      ),
                  ],
                ),
          caption: filtered ? '${rows.length} dari ${app.items.length} barang' : 'Semua barang',
          action: wide ? PillAction(label: 'Barang baru', icon: Icons.add_rounded, onPressed: onAdd) : null,
        ),
        if (rows.isEmpty)
          AdminEmpty(
            title: app.items.isEmpty ? 'Inventaris masih kosong' : 'Tidak ada yang cocok',
            message: app.items.isEmpty
                ? 'Belum ada barang dalam inventaris. Tambahkan barang pertama.'
                : 'Tidak ada barang yang cocok dengan pencarian atau kategori ini.',
            icon: app.items.isEmpty ? Icons.inventory_2_outlined : Icons.search_off_rounded,
            action: app.items.isEmpty
                ? FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah barang pertama'),
                  )
                : OutlinedButton(onPressed: _clear, child: const Text('Hapus filter')),
          )
        else
          AdminGrid(
            children: [for (final item in rows) KeyedSubtree(key: ValueKey(item.id), child: _row(item))],
          ),
        if (!wide) ...[AdminFab(label: 'Barang baru', onPressed: onAdd), const SizedBox(height: AdminFab.clearance)],
      ],
    );
  }

  /// AgroLens article row: shaped picture, name, category and ready units,
  /// a pill when the item is not lent out; edit and delete at the end.
  Widget _row(InventoryItem item) {
    final locked = a.locked;
    return ManageRow(
      onTap: locked ? null : () => edit(item),
      leading: ShapedThumb(category: item.category, imageUrl: item.imageUrl, picture: a.picture, enabled: item.enabled),
      title: item.name,
      meta: [
        shortId(item.id),
        item.category.isEmpty ? 'Tanpa kategori' : item.category,
        '${item.available}/${item.total} unit siap',
      ].join(' · '),
      pills: [if (!item.enabled) const StatusPill('Tidak dipinjamkan', tone: Tone.bad, dense: true)],
      actions: [
        ShapeAction(icon: Icons.edit_outlined, tooltip: 'Ubah', onPressed: locked ? null : () => edit(item)),
        ShapeAction(
          icon: Icons.delete_outline_rounded,
          tooltip: item.reserved > 0 ? 'Hapus (masih dipinjam)' : 'Hapus',
          shape: ExpressiveShape.burst,
          danger: true,
          onPressed: locked || item.reserved > 0 ? null : () => remove(item),
        ),
      ],
    );
  }
}
