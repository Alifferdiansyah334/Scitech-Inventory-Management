import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_state.dart';
import '../../models.dart';
import '../../services/whatsapp_service.dart';
import '../../ui/tokens.dart';
import '../admin_contact_picker.dart';
import '../catalog/dates.dart';
import '../forms.dart';
import '../workspace.dart';

/// Server actions shared by every workspace section. Mixed into the
/// workspace state so sections receive it as their single action handle.
mixin WorkspaceActions on State<ConnectedWorkspace> {
  bool working = false;
  AppState get app;
  bool get locked => working || app.busy;

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> perform(
    Future<void> Function() action, {
    String success = 'Perubahan tersimpan.',
  }) async {
    if (locked) return;
    setState(() => working = true);
    try {
      await action();
      if (mounted) message(success);
    } catch (e) {
      message(e.toString());
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> loanAction(
    Loan loan,
    String action, {
    Json data = const {},
  }) async {
    await app.mutate(
      'api/loans/${loan.id}',
      method: 'PATCH',
      data: {...data, 'action': action},
    );
  }

  Future<void> approve(Loan loan) => perform(() => loanAction(loan, 'approve'));

  Future<void> photoAction(Loan loan, bool returning) async {
    if (locked) return;
    var note = '';
    if (returning) {
      final form = await promptForm(context, 'Pengembalian ${loan.name}', [
        const InputSpec(
          'note',
          'Catatan kondisi barang',
          optional: true,
          max: 1000,
        ),
      ], submit: 'Lanjut pilih foto');
      if (form == null || !mounted) return;
      note = form['note'] ?? '';
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (picked == null || !mounted) return;
    var persisted = false;
    await perform(
      () async {
        final id = await app.api.upload(picked, bucket: 'return-images');
        await loanAction(
          loan,
          returning ? 'requestReturn' : 'handover',
          data: {
            returning ? 'return_image_id' : 'admin_image_id': id,
            if (returning) 'user_note': note,
          },
        );
        persisted = true;
      },
      success: returning
          ? 'Pengembalian diajukan untuk diperiksa.'
          : 'Serah terima berhasil dicatat.',
    );
    if (returning && persisted && mounted && app.adminContacts.isNotEmpty) {
      await _offerReturnConfirmation(loan, note);
    }
  }

  Future<void> _offerReturnConfirmation(
    Loan loan,
    String note,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Pengembalian diajukan'),
      content: const Text(
        'Foto dan catatan kondisi sudah tersimpan. Admin akan memeriksa pengembalian. Anda juga dapat mengirim konfirmasi melalui WhatsApp.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Selesai'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final contact = await chooseAdminContact(
              dialogContext,
              app.adminContacts,
            );
            if (contact == null || !mounted) return;
            try {
              final launched = await WhatsAppService.sendReturnProofMessage(
                phoneNumber: contact.phone,
                borrowerName: app.profile!.name,
                itemName: loan.name,
                borrowDate: loan.borrowDate,
                dueDate: DateTime.now(),
                note: note.isEmpty
                    ? 'Bukti foto sudah diunggah pada aplikasi.'
                    : note,
              );
              if (!launched) {
                message(
                  'WhatsApp belum dapat dibuka. Pengembalian tetap tercatat.',
                );
              }
            } catch (_) {
              message(
                'WhatsApp belum dapat dibuka. Pengembalian tetap tercatat.',
              );
            }
          },
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Konfirmasi WhatsApp'),
        ),
      ],
    ),
  );

  Future<void> noteAction(
    Loan loan,
    String action,
    String title, {
    bool requiredNote = true,
  }) async {
    final values = await promptForm(context, title, [
      InputSpec(
        'note',
        'Catatan',
        optional: !requiredNote,
        min: requiredNote ? 5 : 1,
        max: 1000,
      ),
    ]);
    if (values == null || !mounted) return;
    await perform(
      () => loanAction(
        loan,
        action,
        data: {
          action == 'flagIssue' ? 'issue_note' : 'admin_note': values['note'],
        },
      ),
    );
  }

  Future<void> confirmReturn(Loan loan) async {
    if (await confirmAction(
      context,
      'Barang sudah diperiksa?',
      'Konfirmasi akan mengembalikan ${loan.quantity} unit ke stok tersedia.',
    )) {
      await perform(
        () => loanAction(
          loan,
          'confirmReturn',
          data: {
            'actual_return_date': DateTime.now().toUtc().toIso8601String(),
          },
        ),
      );
    }
  }

  Future<void> contactAdmin(Loan loan) async {
    final contact = await chooseAdminContact(context, app.adminContacts);
    if (contact == null || !mounted) return;
    try {
      final sent = await WhatsAppService.contact(
        contact.phone,
        'Halo Admin, saya ${app.profile!.name} ingin menanyakan peminjaman ${loan.name} (${loan.quantity} unit).\nNomor pengajuan: ${loan.id}\nStatus: ${loan.label}\nBatas kembali: ${shortDate(loan.dueDate)}',
      );
      if (!sent) message('WhatsApp belum dapat dibuka. Coba kembali.');
    } catch (_) {
      message('WhatsApp belum dapat dibuka. Coba kembali.');
    }
  }

  /// Server image for [value] (path or id), or a navySoft placeholder.
  Widget picture(String value, {IconData icon = Icons.inventory_2_outlined}) {
    final url = value.isEmpty ? '' : app.api.imageUrl(value);
    if (url.isEmpty) {
      return ColoredBox(
        color: AppColors.navySoft,
        child: Center(child: Icon(icon, color: AppColors.navy, size: 32)),
      );
    }
    return Image.network(
      url,
      headers: app.api.authHeaders,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.navySoft,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}
