import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../models.dart';
import '../services/whatsapp_service.dart';
import 'app.dart';
import 'borrower_catalog.dart' show shortDate;
import 'admin_contact_picker.dart';

class BorrowRequestPage extends StatefulWidget {
  const BorrowRequestPage({required this.app, required this.item, super.key});
  final AppState app;
  final InventoryItem item;
  @override
  State<BorrowRequestPage> createState() => _BorrowRequestPageState();
}

class _BorrowRequestPageState extends State<BorrowRequestPage> {
  final purpose = TextEditingController();
  int quantity = 1, days = 7;
  DateTime? customDate;
  bool busy = false, notify = true, saved = false;
  String? error;
  DateTime get due => customDate ?? DateTime.now().add(Duration(days: days));
  @override
  void dispose() {
    purpose.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || saved) return;
    if (purpose.text.trim().length < 5) {
      setState(() => error = 'Isi keperluan peminjaman minimal 5 karakter.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.app.mutate(
        'api/loans',
        data: {
          'item_id': widget.item.id,
          'quantity': quantity,
          'purpose': purpose.text.trim(),
          'borrow_date': DateTime.now().toUtc().toIso8601String(),
          'return_date': due.toUtc().toIso8601String(),
        },
      );
      if (mounted) setState(() => saved = true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> whatsapp() async {
    final contact = await chooseAdminContact(context, widget.app.adminContacts);
    if (contact == null || !mounted) return;
    try {
      final launched = await WhatsAppService.sendBorrowRequestMessage(
        phoneNumber: contact.phone,
        borrowerName: widget.app.profile!.name,
        itemName: widget.item.name,
        quantity: quantity,
        purpose: purpose.text.trim(),
        borrowDate: DateTime.now(),
        dueDate: due,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp belum dapat dibuka. Pengajuan tetap tersimpan; Anda dapat mencoba lagi.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp belum dapat dibuka. Pengajuan tetap tersimpan.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(saved ? 'Pengajuan berhasil' : 'Ajukan peminjaman'),
        automaticallyImplyLeading: !busy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (saved) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF059669),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pengajuan berhasil!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Permohonan sudah tercatat dan menunggu persetujuan admin. Pantau perkembangannya di Pinjaman saya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 24),
                    summary(),
                    const SizedBox(height: 20),
                    if (notify && widget.app.adminContacts.isNotEmpty) ...[
                      FilledButton.icon(
                        onPressed: whatsapp,
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Kirim notifikasi WhatsApp ke admin'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'WhatsApp terbuka dengan pesan pengajuan yang sudah disiapkan. Tekan Kirim di WhatsApp untuk mengirimnya.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Lihat status pinjaman'),
                    ),
                  ] else ...[
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.item.category} · ${widget.item.available} unit tersedia',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 24),
                    panel(
                      'Jumlah barang',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Kurangi jumlah',
                                onPressed: busy || quantity <= 1
                                    ? null
                                    : () => setState(() => quantity--),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Tambah jumlah',
                                onPressed:
                                    busy || quantity >= widget.item.available
                                    ? null
                                    : () => setState(() => quantity++),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              const SizedBox(width: 10),
                              const Text('unit'),
                            ],
                          ),
                          Text(
                            'Maksimal ${widget.item.available} unit sesuai stok saat ini.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    panel(
                      'Durasi peminjaman',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final d in [1, 3, 7, 14, 30])
                                ChoiceChip(
                                  label: Text('$d hari'),
                                  selected: customDate == null && days == d,
                                  onSelected: busy
                                      ? null
                                      : (_) => setState(() {
                                          days = d;
                                          customDate = null;
                                        }),
                                ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.calendar_month,
                                  size: 17,
                                ),
                                label: const Text('Pilih tanggal'),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        final now = DateTime.now();
                                        final value = await showDatePicker(
                                          context: context,
                                          initialDate: due,
                                          firstDate: now,
                                          lastDate: now.add(
                                            const Duration(days: 365),
                                          ),
                                        );
                                        if (value != null && mounted) {
                                          setState(
                                            () => customDate = DateTime(
                                              value.year,
                                              value.month,
                                              value.day,
                                              23,
                                              59,
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Perkiraan kembali: ${shortDate(due)}',
                            style: const TextStyle(
                              color: indigo,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    panel(
                      'Keperluan peminjaman',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final text in [
                                'Operasional & Proyek',
                                'Maintenance & Perbaikan',
                                'Meeting & Presentasi',
                                'Pengujian',
                                'Acara Internal',
                              ])
                                ActionChip(
                                  label: Text(text),
                                  onPressed: busy
                                      ? null
                                      : () => purpose.text = text,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: purpose,
                            enabled: !busy,
                            minLines: 3,
                            maxLines: 5,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText:
                                  'Jelaskan untuk apa barang akan digunakan...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    panel(
                      'Konfirmasi WhatsApp',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Notifikasi ke admin',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              'Siapkan pesan WhatsApp setelah pengajuan berhasil disimpan.',
                            ),
                            value:
                                notify && widget.app.adminContacts.isNotEmpty,
                            onChanged: busy || widget.app.adminContacts.isEmpty
                                ? null
                                : (v) => setState(() => notify = v),
                          ),
                          if (widget.app.adminContacts.isEmpty)
                            const Text(
                              'Kontak WhatsApp admin belum diatur. Pengajuan tetap dapat dikirim melalui aplikasi.',
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                              ),
                            ),
                          if (widget.app.profile!.phone.isNotEmpty)
                            Text(
                              'Nomor WhatsApp akun Anda: ${widget.app.profile!.phone}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: busy ? null : submit,
                      icon: Icon(
                        busy ? Icons.hourglass_top : Icons.send_outlined,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          busy ? 'Mengirim pengajuan...' : 'Ajukan peminjaman',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pengajuan akan ditinjau admin. Stok diperbarui setelah pengajuan disetujui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget panel(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: navy,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
  Widget summary() => panel(
    'Ringkasan pengajuan',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.item.name} · $quantity unit',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text('Batas kembali: ${shortDate(due)}'),
        const SizedBox(height: 8),
        Text(purpose.text.trim()),
      ],
    ),
  );
}
