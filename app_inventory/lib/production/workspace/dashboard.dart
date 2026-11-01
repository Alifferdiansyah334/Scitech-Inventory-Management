import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'actions.dart';
import 'chrome.dart';
import 'loan_card.dart';
import 'swipe_approve.dart';

/// Admin 'Ringkasan': pending count up front, three live metrics, then the
/// latest requests (pending ones can be swiped right to approve).
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({required this.actions, super.key});
  final WorkspaceActions actions;

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final pending = app.loans.where((l) => l.status == 'pending').length;
    final latest = app.loans.take(5).toList();
    return SectionLayout(
      title: 'Ringkasan',
      extra: _Hero(
        pending: pending,
        metrics: [
          ('${app.items.length}', 'jenis barang'),
          (
            '${app.items.fold<int>(0, (sum, item) => sum + item.available)}',
            'unit tersedia',
          ),
          (
            '${app.loans.where((l) => !l.closed && l.status != 'pending').length}',
            'pinjaman aktif',
          ),
        ],
      ),
      children: [
        SectionTitle(
          'Permintaan terbaru',
          trailing: latest.isEmpty
              ? null
              : Text(
                  '${latest.length} dari ${app.loans.length}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
        ),
        if (latest.isEmpty)
          const StateMessage(
            title: 'Belum ada permintaan',
            message: 'Belum ada permintaan peminjaman.',
            icon: Icons.inbox_outlined,
          )
        else ...[
          for (var i = 0; i < latest.length; i++)
            Padding(
              key: ValueKey(latest[i].id),
              padding: const EdgeInsets.only(bottom: 12),
              child: SpringReveal(
                index: i,
                child: QueueCard(actions: actions, loan: latest[i]),
              ),
            ),
          if (latest.any((l) => l.status == 'pending')) const SwipeHint(),
        ],
      ],
    );
  }
}

/// Loan card that is swipeable when it is a pending request.
class QueueCard extends StatelessWidget {
  const QueueCard({required this.actions, required this.loan, super.key});
  final WorkspaceActions actions;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final card = LoanCard(actions: actions, loan: loan);
    if (loan.status != 'pending' || !actions.app.isAdmin) return card;
    return SwipeToApprove(
      enabled: !actions.locked,
      onApprove: () => actions.approve(loan),
      child: card,
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.pending, required this.metrics});
  final int pending;
  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$pending',
            style: TextStyle(
              fontSize: 72,
              height: 1,
              fontWeight: FontWeight.w700,
              color: pending > 0 ? AppColors.accent : Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'permintaan menunggu persetujuan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                decoration: BoxDecoration(
                  color: AppColors.navy2,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metrics[i].$1,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      metrics[i].$2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.navyMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}
