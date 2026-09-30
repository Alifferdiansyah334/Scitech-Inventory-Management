import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import 'admin_navigation.dart';

class AdminLoanApprovalPage extends StatelessWidget {
  const AdminLoanApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    return AdminScaffold(
      title: 'Persetujuan Peminjaman',
      selectedIndex: 1,
      bodyBuilder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const Text(
            'Permintaan Peminjaman',
            style: TextStyle(
              color: adminNavy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tinjau kebutuhan dan ketersediaan barang sebelum memberi keputusan.',
            style: TextStyle(color: adminMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (store.loans.isEmpty)
            const AdminCard(
              child: Text(
                'Belum ada data peminjaman.',
                style: TextStyle(color: adminMuted),
              ),
            )
          else
            ...store.loans.map(
              (loan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              loan.borrower,
                              style: const TextStyle(
                                color: adminNavy,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          AdminStatusChip(loan.status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _LoanDetail(
                        icon: Icons.inventory_2_outlined,
                        text: '${loan.itemName} • ${loan.quantity} unit',
                      ),
                      const SizedBox(height: 8),
                      _LoanDetail(
                        icon: Icons.calendar_today_outlined,
                        text:
                            'Pinjam ${adminDate(loan.borrowDate)}  •  Kembali ${adminDate(loan.returnDate)}',
                      ),
                      if (loan.status == 'Menunggu') ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reject(context, loan),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Tolak'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(
                                    color: Color(0xFFFECACA),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _approve(context, loan),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Setujui'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: adminIndigo,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _approve(BuildContext context, AdminLoan loan) {
    final approved = AdminStore.instance.approveLoan(loan);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Peminjaman disetujui dan stok diperbarui.'
              : 'Stok tersedia tidak mencukupi untuk permintaan ini.',
        ),
      ),
    );
  }

  void _reject(BuildContext context, AdminLoan loan) {
    AdminStore.instance.rejectLoan(loan);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permintaan peminjaman ditolak.')),
    );
  }
}

class _LoanDetail extends StatelessWidget {
  const _LoanDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: adminMuted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: adminMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
