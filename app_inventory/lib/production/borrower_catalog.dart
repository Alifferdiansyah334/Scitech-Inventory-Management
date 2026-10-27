import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../models.dart';
import 'app.dart';

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

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final categories = ['Semua', ...app.items.map((i) => i.category).toSet()];
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
    final active = app.loans.where((l) => !l.closed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat(
              Icons.inventory_2_outlined,
              'Barang tersedia',
              '${app.items.where((i) => i.canBorrow).length}',
              indigo,
            ),
            _stat(
              Icons.assignment_outlined,
              'Pinjaman saya',
              '$active',
              const Color(0xFFD97706),
            ),
            _stat(
              Icons.people_outline,
              'Sedang dipakai tim',
              '${app.activity.length}',
              const Color(0xFF059669),
            ),
          ],
        ),
        if (active > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Material(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                leading: const Icon(Icons.schedule, color: indigo),
                title: Text(
                  '$active pengajuan dan pinjaman aktif',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Pantau persetujuan, pengambilan, dan pengembalian.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onLoans,
              ),
            ),
          ),
        const SizedBox(height: 24),
        TextField(
          controller: search,
          decoration: InputDecoration(
            hintText: 'Cari barang, kategori, atau deskripsi...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      search.clear();
                      setState(() => query = '');
                    },
                  ),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '$c (${c == 'Semua' ? app.items.length : app.items.where((i) => i.category == c).length})',
                    ),
                    selected: category == c,
                    onSelected: (_) => setState(() => category = c),
                    selectedColor: const Color(0xFFEEF0FF),
                    labelStyle: TextStyle(
                      color: category == c ? indigo : Colors.blueGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'Menampilkan ${rows.length} barang',
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilterChip(
                  label: const Text('Tersedia saja'),
                  selected: availableOnly,
                  onSelected: (v) => setState(() => availableOnly = v),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Tampilan grid',
                  onPressed: () => setState(() => grid = true),
                  isSelected: grid,
                  icon: const Icon(Icons.grid_view_rounded),
                ),
                IconButton(
                  tooltip: 'Tampilan daftar',
                  onPressed: () => setState(() => grid = false),
                  isSelected: !grid,
                  icon: const Icon(Icons.view_agenda_outlined),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 46, color: Colors.blueGrey),
                const SizedBox(height: 12),
                Text(
                  app.items.isEmpty
                      ? 'Belum ada barang dalam inventaris.'
                      : 'Tidak ada barang yang cocok.',
                ),
                if (app.items.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      search.clear();
                      setState(() {
                        query = '';
                        category = 'Semua';
                        availableOnly = false;
                      });
                    },
                    child: const Text('Reset filter'),
                  ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = !grid
                ? 1
                : constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 340
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final item in rows)
                  SizedBox(width: width, child: _card(item, !grid)),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            const Icon(Icons.people_outline, color: indigo),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Sedang dipakai rekan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onLoans,
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        const Text(
          'Lihat siapa yang memakai barang dan perkiraan kembalinya.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (app.activity.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Belum ada peminjaman aktif dari tim.',
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
        for (final loan in app.activity.take(3)) TeamLoanTile(loan: loan),
      ],
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) =>
      Container(
        width: 195,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _card(InventoryItem item, bool list) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => details(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: list ? 130 : 155,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.picture(item.imageUrl),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: item.canBorrow
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.canBorrow ? 'Tersedia' : 'Tidak tersedia',
                      style: TextStyle(
                        color: item.canBorrow
                            ? const Color(0xFF047857)
                            : Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: indigo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description.isEmpty
                      ? 'Inventaris yang dapat diajukan untuk kebutuhan tim.'
                      : item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                Text(
                  '${item.available} / ${item.total} unit tersedia',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: item.canBorrow
                      ? () => widget.onBorrow(item)
                      : null,
                  child: Text(
                    item.canBorrow
                        ? 'Ajukan peminjaman'
                        : 'Stok tidak tersedia',
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: () => details(item),
                  child: const Text('Lihat detail'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void details(InventoryItem item) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 190, child: widget.picture(item.imageUrl)),
            const SizedBox(height: 18),
            Text(item.category, style: const TextStyle(color: indigo)),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.description.isEmpty
                  ? 'Belum ada deskripsi barang.'
                  : item.description,
            ),
            const SizedBox(height: 16),
            Text(
              'Stok tersedia: ${item.available} dari ${item.total} unit',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            for (final loan in widget.app.activity.where(
              (l) => l.itemId == item.id,
            ))
              TeamLoanTile(loan: loan),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: item.canBorrow
                  ? () {
                      Navigator.pop(context);
                      widget.onBorrow(item);
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Ajukan peminjaman'),
            ),
          ],
        ),
      ),
    ),
  );
}

class TeamLoanTile extends StatelessWidget {
  const TeamLoanTile({required this.loan, super.key});
  final TeamLoan loan;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEEF0FF),
            foregroundColor: indigo,
            child: Text(
              loan.borrowerName.isEmpty
                  ? '?'
                  : loan.borrowerName.substring(0, 1).toUpperCase(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loan.borrowerName}${loan.isMine ? ' (Anda)' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (loan.department.isNotEmpty)
                  Text(
                    loan.department,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${loan.itemName} · ${loan.quantity} unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${statusLabels[loan.status] ?? loan.status} · kembali ${shortDate(loan.dueDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
