import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import 'admin_navigation.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  String selectedType = 'Semua';
  static const types = [
    'Semua',
    'Peminjaman',
    'Persetujuan',
    'Pengembalian',
    'Pengadaan',
  ];

  @override
  Widget build(BuildContext context) {
    final history = AdminStore.instance.history
        .where((entry) => selectedType == 'Semua' || entry.type == selectedType)
        .toList();
    return AdminScaffold(
      title: 'Riwayat',
      selectedIndex: 4,
      bodyBuilder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const Text(
            'Aktivitas Sistem',
            style: TextStyle(
              color: adminNavy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Riwayat peminjaman, keputusan, pengembalian, dan pengadaan.',
            style: TextStyle(color: adminMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = types[index];
                return ChoiceChip(
                  label: Text(type),
                  selected: selectedType == type,
                  onSelected: (_) => setState(() => selectedType = type),
                  selectedColor: adminIndigo,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: adminBorder),
                  labelStyle: TextStyle(
                    color: selectedType == type ? Colors.white : adminMuted,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const AdminCard(
              child: Text(
                'Belum ada riwayat pada kategori ini.',
                style: TextStyle(color: adminMuted),
              ),
            )
          else
            ...history.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: AdminCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Icon(
                          _iconFor(entry.type),
                          size: 18,
                          color: adminIndigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: const TextStyle(
                                color: adminNavy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.detail,
                              style: const TextStyle(
                                color: adminMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${entry.type} • ${adminDate(entry.date)}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

  IconData _iconFor(String type) => switch (type) {
    'Peminjaman' => Icons.inventory_2_outlined,
    'Persetujuan' => Icons.fact_check_outlined,
    'Pengembalian' => Icons.assignment_return_outlined,
    _ => Icons.local_shipping_outlined,
  };
}
