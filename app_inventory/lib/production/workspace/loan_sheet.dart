import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/button_feedback.dart';
import '../../ui/components.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../catalog/dates.dart';
import 'actions.dart';
import 'loan_card.dart';
import 'loan_details.dart';

/// What happens next for an open loan, in the borrower's words.
String loanHint(Loan loan) => switch (loan.status) {
  'pending' => 'Pengajuan terkirim. Menunggu admin meninjau permintaan Anda.',
  'approved' => 'Pengajuan disetujui. Hubungi admin untuk pengambilan barang.',
  'borrowed' || 'overdue' => 'Barang sedang digunakan. Unggah foto kondisi ketika mengajukan pengembalian.',
  'returning' => 'Bukti pengembalian sudah terkirim. Menunggu pemeriksaan admin.',
  'needs_review' => 'Ada catatan pemeriksaan. Periksa catatan admin dan kirim ulang bukti.',
  _ => '',
};

/// The item is with the borrower right now.
bool loanInUse(Loan loan) => !loan.closed && const ['borrowed', 'overdue'].contains(loan.status);

/// "Terlambat 2 hari", "Kembali hari ini" or "Sisa 3 hari".
String loanDueText(Loan loan) {
  final days = daysUntil(loan.dueDate);
  if (loan.late || days < 0) return 'Terlambat ${days < 0 ? -days : 1} hari';
  return days == 0 ? 'Kembali hari ini' : 'Sisa $days hari';
}

/// One of the borrower's loans as a white row (AgroLens history item):
/// the item's photo clipped to its category shape (or the shape itself),
/// name, quantity and the due date or time left, status pill and a shaped
/// arrow. Squashes while held; opens [showLoanSheet].
class MyLoanCard extends StatelessWidget {
  const MyLoanCard({required this.actions, required this.loan, super.key});
  final WorkspaceActions actions;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final item = actions.app.items.where((i) => i.id == loan.itemId).firstOrNull;
    final when = loan.closed
        ? '${dayDate(loan.borrowDate)} – ${dayDate(loan.dueDate)}'
        : loanInUse(loan)
        ? loanDueText(loan)
        : 'kembali ${dayDate(loan.dueDate)}';
    return Semantics(
      container: true,
      button: true,
      child: PressSpring(
        scale: .97,
        squash: .05,
        child: Builder(
          builder: (context) {
            final press = PressSpring.progressOf(context);
            Widget card(double p) {
              // Corners round further while held (AgroLens Tappable morph).
              final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24 + 8 * p.clamp(0.0, 1.0)));
              return Material(
                color: AppColors.card,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                animationDuration: Duration.zero,
                child: InkWell(
                  customBorder: shape,
                  onTap: tactileTap(() => showLoanSheet(context, actions, loan.id)),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 60,
                          child: item != null && item.imageUrl.isNotEmpty
                              ? ShapeClip(
                                  shape: categoryStyle(item.category).shape,
                                  child: actions.picture(item.imageUrl),
                                )
                              : ShapeIcon.category(item?.category ?? '', size: 60),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall?.copyWith(color: AppColors.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${loan.quantity} unit · $when',
                                style: text.bodySmall?.copyWith(color: AppColors.muted, fontFeatures: tabular),
                              ),
                              const SizedBox(height: 6),
                              StatusPill(loan.label, tone: loanTone(loan.status, late: loan.late), dense: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Transform.translate(
                          offset: Offset(4 * p, 0),
                          child: ShapeIcon(
                            icon: Icons.arrow_forward_rounded,
                            shape: ExpressiveShape.cookie9,
                            size: 34,
                            fill: AppColors.highest,
                            foreground: AppColors.primary,
                            iconScale: .5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return press == null ? card(0) : AnimatedBuilder(animation: press, builder: (_, _) => card(press.value));
          },
        ),
      ),
    );
  }
}

/// The borrower's loan in a bottom sheet that follows live data: header
/// with the item shape and status, the stage and next step, the result-style
/// rows of details, then the actions as full-width theme buttons.
Future<void> showLoanSheet(BuildContext context, WorkspaceActions actions, String loanId) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColors.page,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  clipBehavior: Clip.antiAlias,
  sheetAnimationStyle: sheetAnimation(context),
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) => ListenableBuilder(
    listenable: actions.app,
    builder: (context, _) {
      final loan = actions.app.loans.where((l) => l.id == loanId).firstOrNull;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: loan == null
              ? StateMessage(
                  title: 'Pinjaman tidak ditemukan',
                  message: 'Pinjaman ini sudah tidak ada di daftar. Tutup lembar ini dan muat ulang.',
                  icon: Icons.inbox_outlined,
                  action: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                )
              : _LoanSheetBody(actions: actions, loan: loan),
        ),
      );
    },
  ),
);

class _LoanSheetBody extends StatelessWidget {
  const _LoanSheetBody({required this.actions, required this.loan});
  final WorkspaceActions actions;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final item = app.items.where((i) => i.id == loan.itemId).firstOrNull;
    final buttons = loanButtons(actions, loan);
    final hint = loanHint(loan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 72,
                child: item != null && item.imageUrl.isNotEmpty
                    ? ShapeClip(shape: categoryStyle(item.category).shape, child: actions.picture(item.imageUrl))
                    : ShapeIcon.category(item?.category ?? '', size: 72),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(loan.label, tone: loanTone(loan.status, late: loan.late)),
                    const SizedBox(height: AppSpace.sm),
                    Text(loan.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      '${loan.quantity} unit · ${loan.itemId}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted, fontFeatures: tabular),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!loan.closed) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tahap pinjaman',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.muted),
                      ),
                    ),
                    if (loanInUse(loan))
                      Flexible(
                        child: Text(
                          loanDueText(loan),
                          textAlign: TextAlign.end,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: loan.late ? AppColors.error : AppColors.ink),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                LoanStageBar(loan),
                if (hint.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(hint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink)),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        LoanDetails(actions: actions, loan: loan),
        if (buttons != null) ...[const SizedBox(height: 20), buttons],
        if (!loan.closed) ...[
          const SizedBox(height: AppSpace.sm),
          OutlinedButton.icon(
            onPressed: app.adminContacts.isEmpty ? null : () => actions.contactAdmin(loan),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Hubungi admin via WhatsApp'),
          ),
        ],
      ],
    );
  }
}
