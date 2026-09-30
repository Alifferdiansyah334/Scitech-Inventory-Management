import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import 'admin_navigation.dart';

class AdminProcurementPage extends StatelessWidget {
  const AdminProcurementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminScaffold(
      title: 'Pengadaan Barang',
      selectedIndex: 3,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editProcurement(context),
        backgroundColor: adminIndigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Pengadaan'),
      ),
      bodyBuilder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          const Text(
            'Daftar Pengadaan',
            style: TextStyle(
              color: adminNavy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pantau permintaan dan penerimaan barang inventori.',
            style: TextStyle(color: adminMuted),
          ),
          const SizedBox(height: 18),
          if (store.procurements.isEmpty)
            const AdminCard(
              child: Text(
                'Belum ada pengadaan.',
                style: TextStyle(color: adminMuted),
              ),
            )
          else
            ...store.procurements.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFEEF2FF),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: adminIndigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              record.itemName,
                              style: const TextStyle(
                                color: adminNavy,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Aksi pengadaan',
                            onSelected: (action) {
                              if (action == 'edit') {
                                _editProcurement(context, record);
                              }
                              if (action == 'delete') {
                                AdminStore.instance.deleteProcurement(record);
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
                      const SizedBox(height: 12),
                      Text(
                        '${record.quantity} unit • ${adminDate(record.date)}',
                        style: const TextStyle(
                          color: adminMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supplier: ${record.supplier}',
                        style: const TextStyle(color: adminMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              color: adminMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: record.status,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(12),
                            items: const ['Diajukan', 'Diproses', 'Diterima']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                            onChanged: (status) {
                              if (status != null) {
                                AdminStore.instance.updateProcurementStatus(
                                  record,
                                  status,
                                );
                              }
                            },
                          ),
                        ],
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

  Future<void> _editProcurement(
    BuildContext context, [
    ProcurementRecord? previous,
  ]) async {
    final itemName = TextEditingController(text: previous?.itemName ?? '');
    final quantity = TextEditingController(text: '${previous?.quantity ?? 1}');
    final supplier = TextEditingController(text: previous?.supplier ?? '');
    var date = previous?.date ?? DateTime.now();
    var status = previous?.status ?? 'Diajukan';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(previous == null ? 'Tambah Pengadaan' : 'Edit Pengadaan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: itemName,
                  decoration: adminInput('Nama barang'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: adminInput('Jumlah'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: supplier,
                  decoration: adminInput('Supplier'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: date,
                    );
                    if (selected != null) setDialogState(() => date = selected);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(adminDate(date)),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: adminInput('Status'),
                  items: const ['Diajukan', 'Diproses', 'Diterima']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => status = value ?? status),
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
    if (!context.mounted) return;
    final itemNameValue = itemName.text.trim();
    final quantityValue = quantity.text.trim();
    final supplierValue = supplier.text.trim();
    itemName.dispose();
    quantity.dispose();
    supplier.dispose();
    if (result != true) return;
    final amount = int.tryParse(quantityValue);
    if (itemNameValue.isEmpty ||
        supplierValue.isEmpty ||
        amount == null ||
        amount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data pengadaan dengan benar.')),
      );
      return;
    }
    final record = ProcurementRecord(
      itemName: itemNameValue,
      quantity: amount,
      date: date,
      supplier: supplierValue,
      status: status,
    );
    if (!AdminStore.instance.saveProcurement(record, previous: previous)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengadaan tidak dapat diubah karena stoknya sedang dipinjam.',
          ),
        ),
      );
    }
  }
}
