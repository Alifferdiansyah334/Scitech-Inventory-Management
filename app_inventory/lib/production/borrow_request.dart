import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../models.dart';
import '../services/whatsapp_service.dart';
import '../ui/springs.dart';
import '../ui/tokens.dart';
import 'admin_contact_picker.dart';
import 'request/duration_card.dart';
import 'request/purpose_card.dart';
import 'request/request_parts.dart';
import 'request/request_success.dart';

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

  Future<void> pickDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: due,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (value != null && mounted) {
      setState(
        () => customDate = DateTime(value.year, value.month, value.day, 23, 59),
      );
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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: saved
            ? RequestSuccessView(
                item: widget.item,
                quantity: quantity,
                presetDays: customDate == null ? days : null,
                due: due,
                purpose: purpose.text.trim(),
                onWhatsApp: notify && widget.app.adminContacts.isNotEmpty
                    ? whatsapp
                    : null,
                onDone: () => Navigator.pop(context, true),
              )
            : form(context),
        bottomNavigationBar: saved
            ? null
            : RequestSubmitBar(busy: busy, error: error, onSubmit: submit),
      ),
    ),
  );

  Widget form(BuildContext context) {
    final cards = [
      QuantityCard(
        quantity: quantity,
        max: widget.item.available,
        busy: busy,
        onChanged: (value) => setState(() => quantity = value),
      ),
      DurationCard(
        days: days,
        custom: customDate != null,
        due: due,
        busy: busy,
        onDays: (value) => setState(() {
          days = value;
          customDate = null;
        }),
        onPickDate: pickDate,
      ),
      PurposeCard(controller: purpose, busy: busy),
      NotifyCard(
        value: notify,
        hasContacts: widget.app.adminContacts.isNotEmpty,
        phone: widget.app.profile!.phone,
        busy: busy,
        onChanged: (value) => setState(() => notify = value),
      ),
    ];
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RequestHeader(
            item: widget.item,
            onBack: busy ? null : () => Navigator.maybePop(context),
          ),
          ColoredBox(
            color: AppColors.navy,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.sheet),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: centered(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, card) in cards.indexed) ...[
                      if (i > 0) const SizedBox(height: 12),
                      SpringReveal(index: i, child: card),
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
}
