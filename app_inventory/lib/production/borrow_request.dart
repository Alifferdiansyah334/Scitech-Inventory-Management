import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_state.dart';
import '../core/appearance.dart';
import '../models.dart';
import '../services/whatsapp_service.dart';
import '../ui/components.dart';
import '../ui/shapes.dart';
import 'admin_contact_picker.dart';
import 'catalog/dates.dart';
import 'request/duration_card.dart';
import 'request/form_rows.dart';
import 'request/purpose_card.dart';
import 'request/request_parts.dart';
import 'request/request_success.dart';

class BorrowRequestPage extends StatefulWidget {
  const BorrowRequestPage({required this.app, required this.item, this.picture, super.key});
  final AppState app;
  final InventoryItem item;

  /// Renders the item photo on the summary card when given.
  final Widget Function(String)? picture;
  @override
  State<BorrowRequestPage> createState() => _BorrowRequestPageState();
}

class _BorrowRequestPageState extends State<BorrowRequestPage> {
  final _form = GlobalKey<FormState>();
  final purpose = TextEditingController();
  int quantity = 1, days = 7;
  DateTime? customDate;
  bool busy = false, notify = true, saved = false;
  bool _notifyDefaulted = false;
  String? error;
  DateTime get due => customDate ?? DateTime.now().add(Duration(days: days));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notifyDefaulted) return;
    _notifyDefaulted = true;
    notify = AppearanceScope.of(context).whatsappByDefault;
  }

  @override
  void dispose() {
    purpose.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || saved) return;
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
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
      if (mounted) {
        // The receipt bursts shapes from its badge as it appears.
        HapticFeedback.mediumImpact();
        setState(() => saved = true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => error = e.toString());
      }
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
      setState(() => customDate = DateTime(value.year, value.month, value.day, 23, 59));
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
            content: Text('WhatsApp belum dapat dibuka. Pengajuan tetap tersimpan; Anda dapat mencoba lagi.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('WhatsApp belum dapat dibuka. Pengajuan tetap tersimpan.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: saved
        ? RequestSuccessView(
            item: widget.item,
            quantity: quantity,
            presetDays: customDate == null ? days : null,
            due: due,
            purpose: purpose.text.trim(),
            onWhatsApp: notify && widget.app.adminContacts.isNotEmpty ? whatsapp : null,
            onDone: () => Navigator.pop(context, true),
          )
        : form(),
  );

  /// AgroLens article editor: AppBar title, Form(ListView) padded 16/8/28
  /// with the item card, the quantity and duration group cards, the purpose
  /// editor card with suggestions and the notify toggle card; the primary
  /// action 56 tall stays in the bottom bar.
  Widget form() => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Kembali',
        onPressed: busy ? null : () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('Ajukan pinjaman'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          centered(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RequestItemSummary(item: widget.item, picture: widget.picture),
                const SizedBox(height: 16),
                GroupCard(
                  title: 'Jumlah',
                  icon: Icons.inventory_2_outlined,
                  value: '$quantity unit',
                  child: QuantityRow(
                    item: widget.item,
                    quantity: quantity,
                    busy: busy,
                    onChanged: (value) => setState(() => quantity = value),
                  ),
                ),
                const SizedBox(height: 12),
                GroupCard(
                  title: 'Lama pinjam',
                  icon: Icons.schedule_rounded,
                  shape: ExpressiveShape.sunny8,
                  value: customDate == null ? '$days hari · kembali ${dayDate(due)}' : 'Kembali ${dayDate(due)}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DurationSection(
                        days: days,
                        custom: customDate != null,
                        busy: busy,
                        onDays: (value) => setState(() {
                          days = value;
                          customDate = null;
                        }),
                      ),
                      const SizedBox(height: 10),
                      ReturnDateRow(due: due, custom: customDate != null, busy: busy, onPickDate: pickDate),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PurposeSection(controller: purpose, busy: busy),
                const SizedBox(height: 16),
                NotifyToggleCard(
                  value: notify,
                  hasContacts: widget.app.adminContacts.isNotEmpty,
                  phone: widget.app.profile!.phone,
                  busy: busy,
                  onChanged: (value) => setState(() => notify = value),
                ),
                const SizedBox(height: 20),
                const RequestNote('Pengajuan ditinjau admin. Stok berkurang setelah admin menyetujui.'),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: RequestSubmit(busy: busy, error: error, onSubmit: submit),
  );
}
