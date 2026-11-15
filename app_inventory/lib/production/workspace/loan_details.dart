import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/progress.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import '../catalog/dates.dart';
import 'actions.dart';
import 'admin_rows.dart';
import 'chrome.dart';
import 'loan_card.dart';

part 'loan_details_rows.dart';

/// Body of an opened loan (AgroLens result body): borrower (admin),
/// quantity and length, pick-up and return times, purpose and notes as
/// rows with a small shaped badge, then the
/// stock effect (admin) and handover/return photos. Shared by the borrower's
/// loan sheet, the expanding admin row and the admin queue detail.
class LoanDetails extends StatelessWidget {
  const LoanDetails({required this.actions, required this.loan, this.rowColor, super.key});
  final WorkspaceActions actions;
  final Loan loan;

  /// Fill of the stock card; white by default, a tonal fill when the
  /// details sit on a white card themselves.
  final Color? rowColor;

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final admin = app.isAdmin;
    final item = app.items.where((i) => i.id == loan.itemId).firstOrNull;
    final who = loan.borrower.isEmpty ? 'Peminjam' : loan.borrower;
    final notes = [
      ('Catatan admin', loan.adminNote, Icons.support_agent_rounded),
      ('Catatan peminjam', loan.userNote, Icons.edit_note_rounded),
      ('Catatan pemeriksaan', loan.issueNote, Icons.report_outlined),
    ].where((n) => n.$2.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Rincian', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ink)),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (admin)
              _LedgerRow(
                label: 'Peminjam',
                value: who,
                detail: loan.phone.isEmpty ? null : loan.phone,
                leading: InitialsAvatar(who, size: 30),
              ),
            _LedgerRow(
              icon: Icons.inventory_2_outlined,
              shape: ExpressiveShape.cookie9,
              label: 'Jumlah',
              value: '${loan.quantity} unit · ${loanDays(loan)} hari',
            ),
            _LedgerRow(
              icon: Icons.event_available_outlined,
              shape: ExpressiveShape.clover4,
              label: 'Mulai',
              value: '${dayDate(loan.borrowDate)}, ${clockTime(loan.borrowDate)}',
            ),
            _LedgerRow(
              icon: Icons.event_outlined,
              shape: ExpressiveShape.sunny8,
              label: 'Batas kembali',
              value: '${dayDate(loan.dueDate)}, ${clockTime(loan.dueDate)}',
            ),
            if (loan.purpose.isNotEmpty)
              _LedgerRow(
                icon: Icons.flag_outlined,
                shape: ExpressiveShape.gem,
                label: 'Keperluan',
                value: loan.purpose,
              ),
            for (final (label, note, icon) in notes)
              _LedgerRow(icon: icon, shape: ExpressiveShape.arch, label: label, value: note),
          ],
        ),
        if (admin && item != null) ...[
          const SizedBox(height: AppSpace.md),
          _StockImpact(loan: loan, item: item, color: rowColor ?? AppColors.card),
        ],
        if (loan.beforeId != null || loan.afterId != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.lg),
            child: Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              children: [
                if (loan.beforeId != null) _photo('Foto serah terima', loan.beforeId!),
                if (loan.afterId != null) _photo('Foto pengembalian', loan.afterId!),
              ],
            ),
          ),
      ],
    );
  }

  Widget _photo(String label, String id) => SizedBox(
    width: 160,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(width: 160, height: 100, child: actions.picture('/api/images/$id/')),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    ),
  );
}

/// Every action a loan offers, by role and status. Null when none applies.
/// [height] sizes the connected Tolak | Setujui group.
Widget? loanButtons(WorkspaceActions a, Loan loan, {double height = 56}) {
  final admin = a.app.isAdmin;
  VoidCallback? guard(VoidCallback callback) => a.locked ? null : callback;
  final pendingAdmin = admin && loan.status == 'pending';
  final cancel = loan.status == 'pending' || admin && loan.status == 'approved';
  final others = <Widget>[
    if (admin && loan.status == 'approved')
      tonalAction('Serah terima + foto', Icons.photo_camera_outlined, guard(() => a.photoAction(loan, false))),
    if (!admin && loan.canReturn)
      FilledButton.icon(
        onPressed: guard(() => a.photoAction(loan, true)),
        icon: const Icon(Icons.assignment_return_outlined),
        label: const Text('Ajukan pengembalian + foto'),
      ),
    if (admin && const ['returning', 'needs_review'].contains(loan.status)) ...[
      tonalAction('Konfirmasi diterima', Icons.task_alt, guard(() => a.confirmReturn(loan))),
      if (loan.status == 'returning')
        tonalAction(
          'Perlu tindak lanjut',
          Icons.report_outlined,
          guard(() => a.noteAction(loan, 'flagIssue', 'Catatan pemeriksaan')),
        ),
    ],
    if (cancel && admin)
      TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        onPressed: guard(() => a.noteAction(loan, 'cancel', 'Alasan pembatalan')),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Batalkan'),
      )
    else if (cancel)
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        onPressed: guard(() => a.noteAction(loan, 'cancel', 'Alasan pembatalan')),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text('Batalkan'),
      ),
  ];
  if (!pendingAdmin && others.isEmpty) return null;
  final size = Size(48, height);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (pendingAdmin)
        ConnectedButtons(
          flex: const [1, 2],
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.high,
                foregroundColor: AppColors.ink,
                minimumSize: size,
                textStyle: TextStyle(fontFamily: AppFonts.sans, fontSize: 17, fontWeight: FontWeight.w700),
                shape: connectedShape(height, first: true, last: false),
              ),
              onPressed: guard(() => a.noteAction(loan, 'reject', 'Alasan penolakan', requiredNote: false)),
              child: const Text('Tolak'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: size,
                textStyle: TextStyle(fontFamily: AppFonts.sans, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              onPressed: guard(() => a.approve(loan)),
              child: const Text('Setujui'),
            ),
          ],
        ),
      if (pendingAdmin && others.isNotEmpty) const SizedBox(height: AppSpace.md),
      if (others.isNotEmpty && admin) Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: others),
      // Borrowers: full-width theme buttons stacked, as in the AgroLens sheet.
      if (others.isNotEmpty && !admin)
        for (final (i, button) in others.indexed) ...[if (i > 0) const SizedBox(height: AppSpace.sm), button],
    ],
  );
}
