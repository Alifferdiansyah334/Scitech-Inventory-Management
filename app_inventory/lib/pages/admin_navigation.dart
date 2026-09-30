import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import 'admin_dashboard_page.dart';
import 'admin_history_page.dart';
import 'admin_inventory_page.dart';
import 'admin_loan_approval_page.dart';
import 'admin_procurement_page.dart';
import 'admin_profile_page.dart';

const adminNavy = Color(0xFF0F172A);
const adminMuted = Color(0xFF64748B);
const adminBorder = Color(0xFFE2E8F0);
const adminCanvas = Color(0xFFF8FAFC);
const adminIndigo = Color(0xFF4F46E5);

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    required this.title,
    required this.selectedIndex,
    required this.bodyBuilder,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final int selectedIndex;
  final WidgetBuilder bodyBuilder;
  final Widget? floatingActionButton;

  static const _destinations = [
    _AdminDestination('Dashboard', Icons.dashboard_outlined),
    _AdminDestination('Persetujuan Peminjaman', Icons.fact_check_outlined),
    _AdminDestination('Kelola Barang', Icons.inventory_2_outlined),
    _AdminDestination('Pengadaan Barang', Icons.local_shipping_outlined),
    _AdminDestination('Riwayat', Icons.history_rounded),
    _AdminDestination('Profil', Icons.person_outline_rounded),
  ];

  static const _pages = <Widget Function()>[
    AdminDashboardPage.new,
    AdminLoanApprovalPage.new,
    AdminInventoryPage.new,
    AdminProcurementPage.new,
    AdminHistoryPage.new,
    AdminProfilePage.new,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdminStore.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: adminCanvas,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: adminNavy,
          elevation: 0,
        ),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFEEF2FF),
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: adminIndigo,
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SIMS ADMIN',
                            style: TextStyle(
                              color: adminNavy,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Sistem Inventori Scitech',
                            style: TextStyle(color: adminMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                for (var index = 0; index < _destinations.length; index++)
                  ListTile(
                    selected: selectedIndex == index,
                    selectedColor: adminIndigo,
                    selectedTileColor: const Color(0xFFEEF2FF),
                    leading: Icon(_destinations[index].icon),
                    title: Text(
                      _destinations[index].label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    onTap: () {
                      Navigator.pop(context);
                      if (selectedIndex != index) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => _pages[index]()),
                        );
                      }
                    },
                  ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Mode administrator • data lokal',
                    style: TextStyle(color: adminMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: bodyBuilder(context),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {this.action, this.onAction, super.key});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: adminNavy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            action!,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
    ],
  );
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Menunggu' || 'Diajukan' => const Color(0xFFD97706),
      'Disetujui' ||
      'Diterima' ||
      'Selesai' ||
      'Tersedia' => const Color(0xFF059669),
      'Ditolak' || 'Habis' => const Color(0xFFDC2626),
      _ => adminIndigo,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: adminBorder),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: child,
    ),
  );
}

String adminDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

InputDecoration adminInput(String label, {String? hint, IconData? icon}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: adminBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: adminBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: adminIndigo, width: 2),
      ),
    );
