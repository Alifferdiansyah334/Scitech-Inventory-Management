import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../models.dart';
import '../ui/components.dart';
import '../ui/controls.dart';
import '../ui/shapes.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';
import '../ui/widgets.dart';
import 'catalog/catalog_parts.dart';
import 'catalog/dates.dart';
import 'catalog/item_details.dart';
import 'catalog/item_row.dart';
import 'workspace/chrome.dart';

export 'catalog/dates.dart' show shortDate;
export 'catalog/team_loan_tile.dart' show TeamLoanTile;

/// Page title on wide panes; phones show "Katalog".
const catalogTitle = 'Katalog Inventaris';

/// Borrower 'Katalog' in the AgroLens library recipe: title with a tonal
/// pill, search, swipeable category chips, the 'Pilihan' carousel of what is
/// most available (only while not searching or filtering), then every item.
class BorrowerCatalog extends StatefulWidget {
  const BorrowerCatalog({
    required this.app,
    required this.picture,
    required this.onBorrow,
    required this.onLoans,
    this.initialCategory,
    super.key,
  });

  /// Category chip selected when the page opens (from Beranda).
  final String? initialCategory;
  final AppState app;
  final Widget Function(String) picture;
  final void Function(InventoryItem) onBorrow;
  final VoidCallback onLoans;
  @override
  State<BorrowerCatalog> createState() => _BorrowerCatalogState();
}

class _BorrowerCatalogState extends State<BorrowerCatalog> {
  String query = '';
  late String category = widget.initialCategory ?? 'Semua';
  bool availableOnly = false;
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reset() {
    search.clear();
    setState(() {
      query = '';
      category = 'Semua';
      availableOnly = false;
    });
  }

  void details(InventoryItem item) =>
      showItemDetails(context, app: widget.app, item: item, picture: widget.picture, onBorrow: widget.onBorrow);

  bool _matches(InventoryItem i, {bool anyCategory = false}) =>
      (anyCategory || category == 'Semua' || i.category == category) &&
      (!availableOnly || i.canBorrow) &&
      '${i.name} ${i.category} ${i.description}'.toLowerCase().contains(query.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final wide = chromeWide(context);
    final names = app.items.map((i) => i.category).toSet();
    final categories = [
      ('Semua', app.items.length),
      for (final name in names) (name, app.items.where((i) => i.category == name).length),
    ];
    final filtering = query.trim().isNotEmpty || category != 'Semua' || availableOnly;
    final rows = app.items.where(_matches).toList();
    // 'Pilihan': what has the most units ready, when there is a choice.
    final featured = app.items.where((i) => i.canBorrow).toList()..sort((a, b) => b.available.compareTo(a.available));
    final failed = app.error != null;
    final updated = app.updatedAt;
    Widget limit(Widget child) => wide
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: child),
          )
        : child;
    return SectionLayout(
      title: catalogTitle,
      phoneTitle: 'Katalog',
      titleTrailing: PillAction(
        label: 'Pinjaman',
        icon: Icons.history_rounded,
        shape: ExpressiveShape.flower8,
        tonal: true,
        onPressed: widget.onLoans,
      ),
      children: [
        limit(
          ExpressiveSearchBar(
            controller: search,
            hintText: 'Cari barang, kategori…',
            onChanged: (v) => setState(() => query = v),
            onClear: () {
              search.clear();
              setState(() => query = '');
            },
          ),
        ),
        CategoryFilterRow(
          categories: categories,
          selected: category,
          onSelect: (c) => setState(() => category = c),
          availableOnly: availableOnly,
          onAvailable: (v) => setState(() => availableOnly = v),
          wrap: wide,
        ),
        if (!filtering && featured.length >= 3) ...[
          const SectionTitle('Pilihan'),
          FeaturedCarousel(items: featured.take(6).toList(), picture: widget.picture, onOpen: details, bleed: !wide),
        ],
        SectionTitle(
          filtering ? '${rows.length} hasil' : 'Semua barang',
          trailing: failed && updated != null
              ? Text(
                  'Tersimpan ${clockTime(updated)}',
                  style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                )
              : null,
        ),
        if (rows.isEmpty) _empty(app) else _ItemList(items: rows, picture: widget.picture, onTap: details),
        if (failed && app.loading) ...[const SizedBox(height: 10), const CatalogReloadRow()],
        const SizedBox(height: 28),
      ],
    );
  }

  /// Empty inventory and "nothing matches" are different messages; the
  /// latter points at matches in other categories when there are any.
  Widget _empty(AppState app) {
    if (app.items.isEmpty) {
      return const CatalogEmpty(
        title: 'Katalog masih kosong',
        message:
            'Belum ada barang dalam inventaris. Barang yang ditambahkan '
            'admin akan muncul di sini.',
        icon: Icons.inventory_2_outlined,
      );
    }
    final where = category == 'Semua' ? '' : ' di $category';
    final elsewhere = category == 'Semua'
        ? const <InventoryItem>[]
        : app.items.where((i) => _matches(i, anyCategory: true)).toList();
    final String message;
    if (elsewhere.isEmpty) {
      message = 'Tidak ada barang yang cocok. Coba kata lain, atau cari di semua kategori.';
    } else if (elsewhere.length == 1) {
      final hit = elsewhere.first;
      message = '${hit.name} (${shortId(hit.id)}) ada di ${hit.category}.';
    } else {
      message = '${elsewhere.length} barang yang cocok ada di kategori lain.';
    }
    final resetButton = FilledButton.tonalIcon(
      onPressed: reset,
      icon: const Icon(Icons.filter_alt_off_outlined),
      label: const Text('Reset filter'),
    );
    return CatalogEmpty(
      title: query.trim().isEmpty ? 'Tidak ada barang$where' : 'Tidak ada “${query.trim()}”$where',
      message: message,
      icon: Icons.search_rounded,
      action: elsewhere.isEmpty
          ? resetButton
          : FilledButton.icon(
              onPressed: () => setState(() => category = 'Semua'),
              icon: const Icon(Icons.grid_view_rounded),
              label: Text('Lihat ${elsewhere.length} hasil di Semua'),
            ),
      secondaryAction: elsewhere.isEmpty ? null : resetButton,
    );
  }
}

/// Item rows 10 apart; two columns on wide panes.
class _ItemList extends StatelessWidget {
  const _ItemList({required this.items, required this.picture, required this.onTap});
  final List<InventoryItem> items;
  final Widget Function(String) picture;
  final ValueChanged<InventoryItem> onTap;

  Widget _row(int i) => Reveal(
    key: ValueKey(items[i].id),
    index: i > 6 ? 6 : i,
    child: ItemRow(item: items[i], picture: picture, onTap: () => onTap(items[i])),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 720) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(height: 10), _row(i)],
          ],
        );
      }
      final width = (box.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (var i = 0; i < items.length; i++) SizedBox(width: width, child: _row(i))],
      );
    },
  );
}
