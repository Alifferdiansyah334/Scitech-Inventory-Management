import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_state.dart';
import '../../models.dart';
import '../../services/whatsapp_service.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
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

  /// Themed floating snackbar (AgroLens); a new message replaces the shown one.
  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> perform(
    Future<void> Function() action, {
    String success = 'Perubahan tersimpan.',
    bool celebrate = false,
  }) async {
    if (locked) return;
    setState(() => working = true);
    try {
      await action();
      if (mounted) {
        message(success);
        // A shape burst confirms work that moved forward (approve, hand
        // over, receive); errors and deletions stay quiet.
        if (celebrate) celebrateFrom(context);
      }
    } catch (e) {
      message(e.toString());
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> loanAction(Loan loan, String action, {Json data = const {}}) async {
    await app.mutate('api/loans/${loan.id}', method: 'PATCH', data: {...data, 'action': action});
  }

  Future<void> approve(Loan loan) => perform(() => loanAction(loan, 'approve'), celebrate: true);

  Future<void> photoAction(Loan loan, bool returning) async {
    if (locked) return;
    var note = '';
    if (returning) {
      final form = await promptForm(
        context,
        'Pengembalian ${loan.name}',
        [const InputSpec('note', 'Catatan kondisi barang', optional: true, max: 1000)],
        submit: 'Lanjut pilih foto',
        icon: Icons.assignment_return_outlined,
      );
      if (form == null || !mounted) return;
      note = form['note'] ?? '';
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 75);
    if (picked == null || !mounted) return;
    var persisted = false;
    await perform(
      () async {
        final id = await app.api.upload(picked, bucket: 'return-images');
        await loanAction(
          loan,
          returning ? 'requestReturn' : 'handover',
          data: {returning ? 'return_image_id' : 'admin_image_id': id, if (returning) 'user_note': note},
        );
        persisted = true;
      },
      success: returning ? 'Pengembalian diajukan untuk diperiksa.' : 'Serah terima berhasil dicatat.',
      celebrate: true,
    );
    if (returning && persisted && mounted && app.adminContacts.isNotEmpty) {
      await _offerReturnConfirmation(loan, note);
    }
  }

  /// AgroLens confirmation dialog: shaped success badge (48), titleLarge,
  /// bodyMedium message, text 'Selesai' and the filled WhatsApp follow-up.
  Future<void> _offerReturnConfirmation(Loan loan, String note) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      icon: ShapeIcon(
        icon: Icons.check_rounded,
        shape: ExpressiveShape.flower8,
        size: 48,
        fill: AppColors.okContainer,
        foreground: AppColors.onOkContainer,
      ),
      title: const Text('Pengembalian diajukan'),
      titleTextStyle: dialogContext.text.titleLarge?.copyWith(color: dialogContext.colors.onSurface),
      content: Text(
        'Foto dan catatan kondisi sudah tersimpan. Admin akan memeriksa pengembalian. Anda juga dapat mengirim konfirmasi melalui WhatsApp.',
        style: dialogContext.text.bodyMedium?.copyWith(color: dialogContext.colors.onSurfaceVariant),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Selesai')),
        FilledButton.icon(
          onPressed: () async {
            final contact = await chooseAdminContact(dialogContext, app.adminContacts);
            if (contact == null || !mounted) return;
            try {
              final launched = await WhatsAppService.sendReturnProofMessage(
                phoneNumber: contact.phone,
                borrowerName: app.profile!.name,
                itemName: loan.name,
                borrowDate: loan.borrowDate,
                dueDate: DateTime.now(),
                note: note.isEmpty ? 'Bukti foto sudah diunggah pada aplikasi.' : note,
              );
              if (!launched) {
                message('WhatsApp belum dapat dibuka. Pengembalian tetap tercatat.');
              }
            } catch (_) {
              message('WhatsApp belum dapat dibuka. Pengembalian tetap tercatat.');
            }
          },
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Konfirmasi WhatsApp'),
        ),
      ],
    ),
  );

  Future<void> noteAction(Loan loan, String action, String title, {bool requiredNote = true}) async {
    final values = await promptForm(context, title, [
      InputSpec('note', 'Catatan', optional: !requiredNote, min: requiredNote ? 5 : 1, max: 1000),
    ], icon: Icons.sticky_note_2_outlined);
    if (values == null || !mounted) return;
    await perform(
      () => loanAction(loan, action, data: {action == 'flagIssue' ? 'issue_note' : 'admin_note': values['note']}),
    );
  }

  Future<void> confirmReturn(Loan loan) async {
    if (await confirmAction(
      context,
      'Barang sudah diperiksa?',
      'Konfirmasi akan mengembalikan ${loan.quantity} unit ke stok tersedia.',
      icon: Icons.fact_check_outlined,
    )) {
      await perform(
        () => loanAction(loan, 'confirmReturn', data: {'actual_return_date': DateTime.now().toUtc().toIso8601String()}),
        celebrate: true,
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

  /// Server image for [value] (path or id), or a fixed-tint placeholder.
  Widget picture(String value, {IconData icon = Icons.inventory_2_outlined}) {
    final url = value.isEmpty ? '' : app.api.imageUrl(value);
    if (url.isEmpty) {
      return ColoredBox(
        color: AppColors.fixed,
        child: Center(child: Icon(icon, color: AppColors.onFixed, size: 32)),
      );
    }
    // Tonal fill while loading, then the photo fades in (AgroLens AppImage);
    // a cached frame shows at once without the fade. Photos (up to 2 MB) are
    // decoded at the size they are shown, not full resolution, which keeps
    // memory and decode time low on modest phones.
    return ColoredBox(
      color: AppColors.high,
      child: LayoutBuilder(
        builder: (context, box) {
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final side = [box.maxWidth, box.maxHeight].where((v) => v.isFinite).fold(0.0, (a, b) => a > b ? a : b);
          return Image.network(
            url,
            headers: app.api.authHeaders,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // Cover crops, so decode the longer side; round up to 64 px steps
            // so small layout changes reuse the cached image.
            cacheWidth: side == 0 ? null : ((side * dpr / 64).ceil() * 64),
            frameBuilder: (context, child, frame, sync) => sync || reducedMotion(context)
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: child,
                  ),
            errorBuilder: (_, _, _) => Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.muted)),
          );
        },
      ),
    );
  }
}
