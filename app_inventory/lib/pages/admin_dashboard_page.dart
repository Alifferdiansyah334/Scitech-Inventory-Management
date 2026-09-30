import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import 'admin_inventory_page.dart';
import 'admin_loan_approval_page.dart';
import 'admin_navigation.dart';
import 'admin_procurement_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminScaffold(
      title: 'Admin Dashboard',
      selectedIndex: 0,
      bodyBuilder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: [
          const Text(
            'Admin Dashboard.',
            style: TextStyle(
              color: adminNavy,
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat datang, ${store.adminName}.',
            style: const TextStyle(
              color: adminMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatTile(
                    width: width,
                    label: 'Total Barang',
                    value: '${store.totalStock}',
                    icon: Icons.inventory_2_outlined,
                    color: adminIndigo,
                  ),
                  _StatTile(
                    width: width,
                    label: 'Barang Tersedia',
                    value: '${store.availableStock}',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF059669),
                  ),
                  _StatTile(
                    width: width,
                    label: 'Sedang Dipinjam',
                    value: '${store.borrowedStock}',
                    icon: Icons.handshake_outlined,
                    color: const Color(0xFF0284C7),
                  ),
                  _StatTile(
                    width: width,
                    label: 'Menunggu Approval',
                    value: '${store.pendingLoans}',
                    icon: Icons.pending_actions_outlined,
                    color: const Color(0xFFD97706),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          AdminSectionTitle(
            'Peminjaman Terbaru',
            action: 'Semua',
            onAction: () => _open(context, const AdminLoanApprovalPage()),
          ),
          const SizedBox(height: 8),
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final loan in store.loans.take(3))
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: adminIndigo,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      loan.itemName,
                      style: const TextStyle(
                        color: adminNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${loan.borrower} • ${loan.quantity} unit',
                      style: const TextStyle(color: adminMuted, fontSize: 12),
                    ),
                    trailing: AdminStatusChip(loan.status),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AdminSectionTitle(
            'Permintaan yang Menunggu Approval',
            action: 'Lihat',
            onAction: () => _open(context, const AdminLoanApprovalPage()),
          ),
          const SizedBox(height: 8),
          if (store.loans.where((loan) => loan.status == 'Menunggu').isEmpty)
            const AdminCard(
              child: Text(
                'Tidak ada permintaan yang menunggu.',
                style: TextStyle(color: adminMuted),
              ),
            )
          else
            ...store.loans
                .where((loan) => loan.status == 'Menunggu')
                .take(2)
                .map(
                  (loan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdminCard(
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: adminIndigo),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loan.borrower,
                                  style: const TextStyle(
                                    color: adminNavy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${loan.itemName} • ${loan.quantity} unit',
                                  style: const TextStyle(
                                    color: adminMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: adminMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 14),
          AdminSectionTitle(
            'Stok Menipis',
            action: 'Kelola',
            onAction: () => _open(context, const AdminInventoryPage()),
          ),
          const SizedBox(height: 8),
          if (store.inventory.where((item) => item.availableStock <= 3).isEmpty)
            const AdminCard(
              child: Text(
                'Semua stok dalam kondisi aman.',
                style: TextStyle(color: adminMuted),
              ),
            )
          else
            ...store.inventory
                .where((item) => item.availableStock <= 3)
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdminCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: adminNavy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${item.availableStock} tersedia',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Buka pengadaan',
                            onPressed: () =>
                                _open(context, const AdminProcurementPage()),
                            icon: const Icon(
                              Icons.add_box_outlined,
                              color: adminIndigo,
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

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: adminNavy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              color: adminMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
