import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/admin_store.dart';
import '../data/loan_store.dart';
import '../services/whatsapp_service.dart';

class ReturnLoanPage extends StatefulWidget {
  const ReturnLoanPage({required this.loan, super.key});

  final LoanRecord loan;

  @override
  State<ReturnLoanPage> createState() => _ReturnLoanPageState();
}

class _ReturnLoanPageState extends State<ReturnLoanPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;
    setState(() {
      _selectedImage = picked;
    });
  }

  Future<void> _submitReturn() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto kondisi barang wajib diunggah sebelum pengembalian.'),
        ),
      );
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keterangan pengembalian harus diisi.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final updated = LoanStore.instance.submitReturnProof(
      loanId: widget.loan.id,
      photoPath: _selectedImage!.path,
      note: note,
    );
    final adminUpdated = AdminStore.instance.submitReturnProof(
      loanId: widget.loan.id,
      photoPath: _selectedImage!.path,
      note: note,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (updated && adminUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pengembalian berhasil dikirim dan menunggu konfirmasi admin.'),
        ),
      );
      setState(() {});
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gagal menyimpan bukti pengembalian. Silakan coba lagi.'),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final note = _noteController.text.trim();
    final success = await WhatsAppService.sendReturnProofMessage(
      phoneNumber: AdminStore.instance.adminPhone,
      borrowerName: widget.loan.borrowerName,
      itemName: widget.loan.itemName,
      borrowDate: widget.loan.borrowDate,
      dueDate: widget.loan.dueDate,
      note: note.isEmpty ? 'Barang dikembalikan dalam kondisi baik.' : note,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp dibuka dengan pesan yang sudah terisi.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp tidak ditemukan. Silakan gunakan WhatsApp/WhatsApp Web secara manual.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitted = widget.loan.status == 'Menunggu Konfirmasi Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengembalian Barang'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.loan.itemName,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Tanggal Pinjam', value: _formatDate(widget.loan.borrowDate)),
          _InfoRow(label: 'Batas Pengembalian', value: _formatDate(widget.loan.dueDate)),
          _InfoRow(label: 'Status', value: widget.loan.status),
          const SizedBox(height: 20),
          const Text(
            'Foto Kondisi Barang Setelah Digunakan',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Ambil Foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih Galeri'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImage != null || widget.loan.borrowerReturnPhotoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(_selectedImage?.path ?? widget.loan.borrowerReturnPhotoPath ?? ''),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'Belum ada foto yang dipilih',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
          if (_selectedImage != null || widget.loan.borrowerReturnPhotoPath != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _selectedImage = null;
                }),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Hapus / Ganti Foto'),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Keterangan Pengembalian',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Barang dikembalikan dalam kondisi baik.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting || isSubmitted ? null : _submitReturn,
            icon: const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Bukti Pengembalian'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isSubmitted) ...[
            OutlinedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.message_rounded),
              label: const Text('Kirim Bukti ke WhatsApp'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
