import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../models.dart';
import '../ui/components.dart';
import '../ui/springs.dart';
import '../ui/tokens.dart';
import 'catalog/catalog_parts.dart';
import 'catalog/item_card.dart';
import 'catalog/item_details.dart';
import 'catalog/team_loan_tile.dart';
import 'workspace/chrome.dart';

export 'catalog/dates.dart' show shortDate;
export 'catalog/team_loan_tile.dart' show TeamLoanTile;

/// Borrower catalogue: search in the navy header, active-loan card, category
/// rail, item grid/list, details sheet and colleagues' current usage.
class BorrowerCatalog extends StatefulWidget {
  const BorrowerCatalog({
    required this.app,
    required this.picture,
    required this.onBorrow,
    required this.onLoans,
    super.key,
  });
  final AppState app;
  final Widget Function(String) picture;
  final void Function(InventoryItem) onBorrow;
  final VoidCallback onLoans;
  @override
  State<BorrowerCatalog> createState() => _BorrowerCatalogState();
}

class _BorrowerCatalogState extends State<BorrowerCatalog> {
  String query = '', category = 'Semua';
  bool grid = true, availableOnly = false;
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

  void details(InventoryItem item) => showItemDetails(
    context,
    app: widget.app,
    item: item,
    picture: widget.picture,
    onBorrow: widget.onBorrow,
  );

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final names = app.items.map((i) => i.category).toSet();
    final categories = [
      ('Semua', app.items.length),
      for (final name in names)
        (name, app.items.where((i) => i.category == name).length),
    ];
    final rows = app.items
        .where(
          (i) =>
              (category == 'Semua' || i.category == category) &&
              (!availableOnly || i.canBorrow) &&
              '${i.name} ${i.category} ${i.description}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    final open = app.loans.where((l) => !l.closed).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final ready = app.items
        .where((i) => i.enabled)
        .fold<int>(0, (sum, i) => sum + i.available);
    return SectionLayout(
      title: 'Katalog Inventaris',
      extra: CatalogSearch(
        controller: search,
        query: query,
        onChanged: (v) => setState(() => query = v),
        totals: '${app.items.length} barang · $ready unit siap dipinjam',
      ),
      overlap: open.isEmpty
          ? null
          : ActiveLoansCard(
              active: open.length,
              nearest: open
                  .where(
                    (l) => const [
                      'approved',
                      'borrowed',
                      'overdue',
                    ].contains(l.status),
                  )
                  .firstOrNull,
              onTap: widget.onLoans,
            ),
      children: [
        CategoryRail(
          categories: categories,
          selected: category,
          onSelect: (c) => setState(() => category = c),
        ),
        const SizedBox(height: 16),
        _toolbar(rows.length),
        const SizedBox(height: 12),
        if (rows.isEmpty) _empty(app.items.isEmpty) else _grid(rows),
        const SizedBox(height: 24),
        SectionTitle(
          'Sedang dipakai rekan',
          trailing: TextButton(
            onPressed: widget.onLoans,
            child: const Text('Lihat semua'),
          ),
        ),
        if (app.activity.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Belum ada peminjaman aktif dari tim.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        for (final loan in app.activity.take(3)) TeamLoanTile(loan: loan),
      ],
    );
  }

  Widget _toolbar(int shown) => Row(
    children: [
      FilterChip(
        label: const Text('Tersedia saja'),
        avatar: Icon(
          availableOnly ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: availableOnly ? Colors.white : AppColors.ok,
        ),
        selected: availableOnly,
        labelStyle: TextStyle(
          color: availableOnly ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (v) => setState(() => availableOnly = v),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          '$shown barang',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      ),
      _ViewToggle(grid: grid, onChanged: (v) => setState(() => grid = v)),
    ],
  );

  Widget _empty(bool noItems) {
    if (noItems) {
      return const StateMessage(
        title: 'Katalog masih kosong',
        message: 'Belum ada barang dalam inventaris.',
        icon: Icons.inventory_2_outlined,
      );
    }
    final where = category == 'Semua' ? '' : ' di $category';
    return StateMessage(
      title: query.isEmpty
          ? 'Tidak ada barang$where'
          : 'Tidak ada "$query"$where',
      message:
          'Tidak ada barang yang cocok. Coba kata lain, atau cari di semua kategori.',
      action: OutlinedButton(
        onPressed: reset,
        child: const Text('Reset filter'),
      ),
    );
  }

  Widget _grid(List<InventoryItem> rows) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = !grid
          ? (constraints.maxWidth >= 760 ? 2 : 1)
          : constraints.maxWidth >= 1000
          ? 4
          : constraints.maxWidth >= 700
          ? 3
          : constraints.maxWidth >= 300
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < rows.length; i++)
            SizedBox(
              key: ValueKey(rows[i].id),
              width: width,
              child: SpringReveal(
                index: i,
                child: CatalogItemCard(
                  item: rows[i],
                  picture: widget.picture,
                  list: !grid,
                  onDetails: () => details(rows[i]),
                  onBorrow: () => widget.onBorrow(rows[i]),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Grid / list switch with an animated white thumb.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});
  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion(context)
        ? Duration.zero
        : snappyCurve.duration;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: duration,
              curve: snappyCurve,
              alignment: grid ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Tampilan grid',
                isSelected: grid,
                onPressed: () => onChanged(true),
                icon: const Icon(Icons.grid_view_rounded, size: 20),
              ),
              IconButton(
                tooltip: 'Tampilan daftar',
                isSelected: !grid,
                onPressed: () => onChanged(false),
                icon: const Icon(Icons.view_agenda_outlined, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
