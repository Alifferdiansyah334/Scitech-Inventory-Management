import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import 'admin_navigation.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final searchController = TextEditingController();
  String selectedCategory = 'Semua';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    final categories = [
      'Semua',
      ...store.inventory.map((item) => item.category).toSet(),
    ];
    final query = searchController.text.trim().toLowerCase();
    final items = store.inventory.where((item) {
      final matchesCategory =
          selectedCategory == 'Semua' || item.category == selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return AdminScaffold(
      title: 'Kelola Barang',
      selectedIndex: 2,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(context),
        backgroundColor: adminIndigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Barang'),
      ),
      bodyBuilder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          const Text(
            'Inventori',
            style: TextStyle(
              color: adminNavy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${store.inventory.length} jenis barang • ${store.availableStock} unit tersedia',
            style: const TextStyle(color: adminMuted),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: adminInput(
              'Cari barang',
              hint: 'Nama atau kategori',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: categories.contains(selectedCategory)
                ? selectedCategory
                : 'Semua',
            decoration: adminInput('Filter kategori'),
            items: categories
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => selectedCategory = value ?? 'Semua'),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const AdminCard(
              child: Text(
                'Tidak ada barang yang cocok.',
                style: TextStyle(color: adminMuted),
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFEEF2FF),
                            child: Icon(item.icon, color: adminIndigo),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: adminNavy,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: adminMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AdminStatusChip(item.status),
                          PopupMenuButton<String>(
                            tooltip: 'Aksi barang',
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editItem(context, item);
                              }
                              if (action == 'delete') {
                                _deleteItem(context, item);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StockValue(
                            label: 'Total stok',
                            value: item.totalStock,
                          ),
                          _StockValue(
                            label: 'Tersedia',
                            value: item.availableStock,
                          ),
                          _StockValue(
                            label: 'Dipinjam',
                            value: item.borrowedStock,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kondisi: ${item.condition}',
                        style: const TextStyle(
                          color: adminMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editItem(
    BuildContext context, [
    InventoryItem? previous,
  ]) async {
    final name = TextEditingController(text: previous?.name ?? '');
    final category = TextEditingController(
      text: previous?.category ?? 'Elektronik',
    );
    final stock = TextEditingController(text: '${previous?.totalStock ?? 1}');
    var condition = previous?.condition ?? 'Baik';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(previous == null ? 'Tambah Barang' : 'Edit Barang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: adminInput('Nama barang'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: category,
                  decoration: adminInput('Kategori'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: adminInput('Total stok'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: adminInput('Kondisi'),
                  items: const ['Baik', 'Perlu Perbaikan', 'Rusak']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => condition = value ?? condition),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    final nameValue = name.text.trim();
    final categoryValue = category.text.trim();
    final stockValue = stock.text.trim();
    name.dispose();
    category.dispose();
    stock.dispose();
    if (saved != true) return;
    final quantity = int.tryParse(stockValue);
    if (nameValue.isEmpty ||
        categoryValue.isEmpty ||
        quantity == null ||
        quantity < 0) {
      _message('Lengkapi data dengan jumlah stok yang valid.');
      return;
    }
    final item = InventoryItem(
      name: nameValue,
      category: categoryValue,
      totalStock: quantity,
      condition: condition,
      icon: previous?.icon ?? Icons.inventory_2_outlined,
    );
    if (!AdminStore.instance.saveInventory(item, previous: previous)) {
      _message(
        'Total stok tidak boleh lebih rendah dari jumlah yang sedang dipinjam.',
      );
    } else {
      _message(
        previous == null ? 'Barang ditambahkan.' : 'Perubahan barang disimpan.',
      );
    }
  }

  Future<void> _deleteItem(BuildContext context, InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus barang?'),
        content: Text('Barang ${item.name} akan dihapus dari inventori.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!AdminStore.instance.deleteInventory(item)) {
      _message('Barang tidak dapat dihapus selama masih dipinjam.');
    } else {
      _message('Barang dihapus.');
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _StockValue extends StatelessWidget {
  const _StockValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: adminNavy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, style: const TextStyle(color: adminMuted, fontSize: 10)),
      ],
    ),
  );
}
