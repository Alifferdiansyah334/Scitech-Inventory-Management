import 'dart:io';

import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../data/loan_store.dart';
import 'admin_navigation.dart';

class ReturnReviewPage extends StatefulWidget {
  const ReturnReviewPage({required this.loan, super.key});

  final AdminLoan loan;

  @override
  State<ReturnReviewPage> createState() => _ReturnReviewPageState();
}

class _ReturnReviewPageState extends State<ReturnReviewPage> {
  @override
  Widget build(BuildContext context) {
    final currentLoan = widget.loan;
    final beforePhoto = currentLoan.adminBeforePhotoPath ?? '';
    final afterPhoto = currentLoan.borrowerReturnPhotoPath ?? '';
    final returnNote = currentLoan.returnNote ?? 'Tidak ada keterangan';

    return AdminScaffold(
      title: 'Detail Pengembalian',
      selectedIndex: 1,
      bodyBuilder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            currentLoan.borrower,
            style: const TextStyle(
              color: adminNavy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currentLoan.itemName} • ${currentLoan.quantity} unit',
            style: const TextStyle(
              color: adminMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine('Tanggal Pinjam', adminDate(currentLoan.borrowDate)),
                _InfoLine('Tanggal Pengembalian', adminDate(currentLoan.returnDate)),
                _InfoLine('Status', currentLoan.status),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'KONDISI SEBELUM',
            style: TextStyle(
              color: adminNavy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (beforePhoto.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(beforePhoto),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            const AdminCard(
              child: Text(
                'Belum ada foto kondisi sebelum dipinjam.',
                style: TextStyle(color: adminMuted),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'KONDISI SESUDAH',
            style: TextStyle(
              color: adminNavy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (afterPhoto.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(afterPhoto),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            const AdminCard(
              child: Text(
                'Belum ada foto kondisi setelah dikembalikan.',
                style: TextStyle(color: adminMuted),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Keterangan Pengembalian',
            style: TextStyle(
              color: adminNavy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          AdminCard(
            child: Text(
              returnNote,
              style: const TextStyle(color: adminMuted, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _confirmReturn(context, currentLoan),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Konfirmasi Barang Diterima'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markIssue(context, currentLoan),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Ada Masalah'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReturn(BuildContext context, AdminLoan loan) {
    final updated = AdminStore.instance.confirmReturn(
      loanId: loan.id,
      issueNote: null,
    );
    if (updated) {
      LoanStore.instance.confirmReturn(loanId: loan.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang diterima dan stok telah diperbarui.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _markIssue(BuildContext context, AdminLoan loan) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ada Masalah'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Masukkan catatan masalah pengembalian...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final note = controller.text.trim();
    if (note.isEmpty) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Catatan masalah wajib diisi.')),
      );
      return;
    }

    AdminStore.instance.markIssue(loanId: loan.id, issueNote: note);
    LoanStore.instance.flagIssue(loanId: loan.id, issueNote: note);
    messenger?.showSnackBar(
      const SnackBar(content: Text('Status diubah menjadi Perlu Tindak Lanjut.')),
    );
    navigator.pop();
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: adminMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: adminNavy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
