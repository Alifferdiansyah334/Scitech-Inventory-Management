import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/admin_store.dart';
import '../services/whatsapp_service.dart';
import 'admin_navigation.dart';
import 'return_review_page.dart';

class AdminLoanApprovalPage extends StatefulWidget {
  const AdminLoanApprovalPage({super.key});

  @override
  State<AdminLoanApprovalPage> createState() => _AdminLoanApprovalPageState();
}

class _AdminLoanApprovalPageState extends State<AdminLoanApprovalPage> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> _beforePhotoMap = {};

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
          if (store.loans.where((loan) => loan.status == 'Menunggu Konfirmasi Admin').isNotEmpty) ...[
            const Text(
              'Pengembalian Menunggu Konfirmasi',
              style: TextStyle(
                color: adminNavy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...store.loans
                .where((loan) => loan.status == 'Menunggu Konfirmasi Admin')
                .map(
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
                          const SizedBox(height: 12),
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
                          if (loan.returnNote != null && loan.returnNote!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Keterangan: ${loan.returnNote}',
                              style: const TextStyle(
                                color: adminMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (loan.adminBeforePhotoPath != null || _beforePhotoMap[loan.id] != null || loan.borrowerReturnPhotoPath != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'KONDISI SEBELUM',
                              style: TextStyle(
                                color: adminNavy,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (loan.adminBeforePhotoPath != null || _beforePhotoMap[loan.id] != null)
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(_beforePhotoMap[loan.id] ?? loan.adminBeforePhotoPath ?? ''),
                                        height: 140,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                if (loan.borrowerReturnPhotoPath != null) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(loan.borrowerReturnPhotoPath ?? ''),
                                        height: 140,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReturnReviewPage(loan: loan),
                                    ),
                                  ),
                                  icon: const Icon(Icons.remove_red_eye_rounded),
                                  label: const Text('Lihat Detail'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: adminIndigo,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 18),
          ],
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
                      if (loan.status == 'Menunggu' || loan.status == 'Diajukan') ...[
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
                      ] else ...[
                        const SizedBox(height: 14),
                        if (_beforePhotoMap[loan.id] != null || loan.adminBeforePhotoPath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_beforePhotoMap[loan.id] ?? loan.adminBeforePhotoPath ?? ''),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickBeforePhoto(loan),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Foto Kondisi Awal'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _sendBorrowApprovalWhatsApp(loan),
                                icon: const Icon(Icons.message_rounded),
                                label: const Text('Kirim ke WhatsApp'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
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

  Future<void> _pickBeforePhoto(AdminLoan loan) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _beforePhotoMap[loan.id] = picked.path;
      loan.adminBeforePhotoPath = picked.path;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto kondisi awal berhasil diambil.')),
    );
  }

  Future<void> _sendBorrowApprovalWhatsApp(AdminLoan loan) async {
    final success = await WhatsAppService.sendBorrowApprovalMessage(
      phoneNumber: loan.borrowerPhone,
      borrowerName: loan.borrower,
      itemName: loan.itemName,
      borrowDate: loan.borrowDate,
      dueDate: loan.returnDate,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp terbuka dengan template pesan yang siap dikirim.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp tidak ditemukan. Silakan gunakan WhatsApp/WhatsApp Web secara manual.')),
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
