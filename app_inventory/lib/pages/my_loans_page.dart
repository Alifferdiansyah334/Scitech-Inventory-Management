import 'package:flutter/material.dart';

import '../data/loan_store.dart';
import '../data/profile_store.dart';
import '../widgets/profile_menu_button.dart';
import 'catalog_page.dart';

class MyLoansPage extends StatefulWidget {
  const MyLoansPage({super.key});

  @override
  State<MyLoansPage> createState() => _MyLoansPageState();
}

class _MyLoansPageState extends State<MyLoansPage> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loans = LoanStore.instance.records;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Loans'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          const ProfileMenuButton(),
          IconButton(
            key: const ValueKey('my_loans_catalog_button'),
            tooltip: 'Catalog',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CatalogPage()),
            ),
          ),
          IconButton(
            key: const ValueKey('my_loans_logout_button'),
            tooltip: 'Keluar',
            color: const Color(0xFFEF4444),
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ProfileStore.instance.clearSession();
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        children: [
          const Text(
            'Loans Activity.',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Kelola pinjaman Anda dan pantau ketersediaan barang di tim.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          _buildTabs(),
          const SizedBox(height: 18),
          tabIndex == 0 ? _buildMyLoans(loans) : _buildActiveLoans(loans),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Pinjaman Saya',
            active: tabIndex == 0,
            onTap: () => setState(() => tabIndex = 0),
          ),
          _TabButton(
            label: 'Status Pinjaman',
            active: tabIndex == 1,
            onTap: () => setState(() => tabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLoans(List<LoanRecord> loans) {
    if (loans.isEmpty) return _emptyState('Belum ada pinjaman yang diajukan.');
    return Column(
      children: loans.map((loan) => _LoanCard(loan: loan)).toList(),
    );
  }

  Widget _buildActiveLoans(List<LoanRecord> loans) {
    if (loans.isEmpty) {
      return _emptyState('Tidak ada peminjaman aktif saat ini.');
    }
    return Column(
      children: loans
          .where(
            (loan) => loan.status == 'approved' || loan.status == 'overdue',
          )
          .map((loan) => _LoanCard(loan: loan))
          .toList(),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 8)]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});

  final LoanRecord loan;

  @override
  Widget build(BuildContext context) {
    final statusColor = loan.status == 'pending'
        ? const Color(0xFFD97706)
        : const Color(0xFF059669);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Icon(loan.item.icon, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.item.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${loan.quantity} Unit Terpinjam • ${_formatDate(loan.borrowDate)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              loan.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
][month - 1];
