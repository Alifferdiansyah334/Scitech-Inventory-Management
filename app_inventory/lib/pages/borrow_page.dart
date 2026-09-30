import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../data/loan_store.dart';
import '../data/profile_store.dart';
import 'catalog_page.dart';
import 'my_loans_page.dart';

class BorrowPage extends StatefulWidget {
  const BorrowPage({required this.item, super.key});

  final CatalogItem item;

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> {
  final purposeController = TextEditingController();
  DateTime returnDate = DateTime.now().add(const Duration(days: 7));
  int quantity = 1;

  @override
  void dispose() {
    purposeController.dispose();
    super.dispose();
  }

  void submit() {
    if (purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tujuan peminjaman harus diisi')),
      );
      return;
    }

    final availableNow = AdminStore.instance.availableFor(widget.item.name);
    if (availableNow == 0 || quantity > availableNow) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tersedia tidak mencukupi.')),
      );
      return;
    }

    final record = LoanRecord(
      item: widget.item,
      quantity: quantity,
      purpose: purposeController.text.trim(),
      borrowDate: DateTime.now(),
      returnDate: returnDate,
    );
    LoanStore.instance.add(record);
    AdminStore.instance.addBorrowRequest(
      borrower: ProfileStore.instance.profile.name,
      itemName: widget.item.name,
      quantity: quantity,
      borrowDate: record.borrowDate,
      returnDate: record.returnDate,
      onStatusChanged: (status) => record.status = status,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyLoansPage()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = AdminStore.instance.availableFor(widget.item.name);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ajukan Peminjaman'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Katalog',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CatalogPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ItemSummary(item: widget.item),
          const SizedBox(height: 20),
          _SectionLabel(label: 'JUMLAH PEMINJAMAN'),
          const SizedBox(height: 8),
          _QuantityPicker(
            value: quantity,
            max: available,
            onChanged: (value) => setState(() => quantity = value),
          ),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'TUJUAN PEMINJAMAN'),
          const SizedBox(height: 8),
          TextField(
            controller: purposeController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Jelaskan kebutuhan peminjaman...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel(label: 'TANGGAL PENGEMBALIAN'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: returnDate,
              );
              if (picked != null) setState(() => returnDate = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_formatDate(returnDate)),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: const Color(0xFF334155),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: available > 0 ? submit : null,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Ajukan Peminjaman'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Icon(item.icon, color: const Color(0xFF4F46E5), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} unit tersedia',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityPicker extends StatelessWidget {
  const _QuantityPicker({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text(
            '$value unit',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    ),
  );
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
