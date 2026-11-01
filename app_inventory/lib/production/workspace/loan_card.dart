import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../catalog/dates.dart';
import '../catalog/team_loan_tile.dart';
import 'actions.dart';
import 'chrome.dart';

/// Stage progress of an open loan (pending → returned).
double loanProgress(Loan loan) =>
    const {
      'pending': .15,
      'approved': .35,
      'borrowed': .6,
      'overdue': .6,
      'returning': .85,
      'needs_review': .85,
    }[loan.status] ??
    0;

/// Thin stage bar coloured by the loan's tone.
class LoanStageBar extends StatelessWidget {
  const LoanStageBar(this.loan, {super.key});
  final Loan loan;

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    value: loanProgress(loan),
    minHeight: 6,
    color: toneColors(loanTone(loan.status, late: loan.late)).fg,
    backgroundColor: AppColors.paper,
    borderRadius: BorderRadius.circular(6),
  );
}

/// White loan card shared by the admin queue, admin lists and the borrower's
/// own loans. [footer] adds view-specific content above the actions.
class LoanCard extends StatelessWidget {
  const LoanCard({
    required this.actions,
    required this.loan,
    this.footer,
    super.key,
  });
  final WorkspaceActions actions;
  final Loan loan;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final admin = app.isAdmin;
    final item = app.items.where((i) => i.id == loan.itemId).firstOrNull;
    final buttons = _buttons(admin);
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(Icons.inventory_2_outlined, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loan.quantity} unit · kembali ${dayDate(loan.dueDate)}, ${clockTime(loan.dueDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(
                          loan.label,
                          tone: loanTone(loan.status, late: loan.late),
                        ),
                        if (admin) AssetTag(loan.itemId, dark: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (admin) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.paper, thickness: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                PersonAvatar(loan.borrower, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.borrower.isEmpty ? 'Peminjam' : loan.borrower,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Batas kembali ${stamp(loan.dueDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (loan.purpose.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Text(loan.purpose),
            ),
          ],
          for (final (label, note) in [
            ('Catatan admin', loan.adminNote),
            ('Catatan peminjam', loan.userNote),
            ('Catatan pemeriksaan', loan.issueNote),
          ])
            if (note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: note),
                    ],
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          if (admin && loan.status == 'pending' && item != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Stok setelah disetujui: ${item.available - loan.quantity} dari ${item.total}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.available - loan.quantity <= 0
                      ? AppColors.accentText
                      : AppColors.muted,
                ),
              ),
            ),
          if (loan.beforeId != null || loan.afterId != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (loan.beforeId != null)
                    _photo('Foto serah terima', loan.beforeId!),
                  if (loan.afterId != null)
                    _photo('Foto pengembalian', loan.afterId!),
                ],
              ),
            ),
          if (footer != null) ...[const SizedBox(height: 14), footer!],
          if (buttons != null) ...[const SizedBox(height: 16), buttons],
        ],
      ),
    );
  }

  Widget _photo(String label, String id) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: SizedBox(
          width: 130,
          height: 100,
          child: actions.picture('/api/images/$id/'),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ],
  );

  /// Every action the original loan card offered, by role and status.
  Widget? _buttons(bool admin) {
    final a = actions;
    VoidCallback? guard(VoidCallback callback) => a.locked ? null : callback;
    final pendingAdmin = admin && loan.status == 'pending';
    final others = <Widget>[
      if (admin && loan.status == 'approved')
        tonalAction(
          'Serah terima + foto',
          Icons.add_a_photo_outlined,
          guard(() => a.photoAction(loan, false)),
        ),
      if (!admin && loan.canReturn)
        tonalAction(
          'Ajukan pengembalian + foto',
          Icons.assignment_return_outlined,
          guard(() => a.photoAction(loan, true)),
        ),
      if (admin &&
          const ['returning', 'needs_review'].contains(loan.status)) ...[
        tonalAction(
          'Konfirmasi diterima',
          Icons.task_alt,
          guard(() => a.confirmReturn(loan)),
        ),
        if (loan.status == 'returning')
          tonalAction(
            'Perlu tindak lanjut',
            Icons.report_outlined,
            guard(() => a.noteAction(loan, 'flagIssue', 'Catatan pemeriksaan')),
          ),
      ],
      if (loan.status == 'pending' || admin && loan.status == 'approved')
        tonalAction(
          'Batalkan',
          Icons.cancel_outlined,
          guard(() => a.noteAction(loan, 'cancel', 'Alasan pembatalan')),
          danger: true,
        ),
    ];
    if (!pendingAdmin && others.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingAdmin)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: guard(
                    () => a.noteAction(
                      loan,
                      'reject',
                      'Alasan penolakan',
                      requiredNote: false,
                    ),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: guard(() => a.approve(loan)),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Setujui'),
                ),
              ),
            ],
          ),
        if (pendingAdmin && others.isNotEmpty) const SizedBox(height: 10),
        if (others.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: others),
      ],
    );
  }
}
