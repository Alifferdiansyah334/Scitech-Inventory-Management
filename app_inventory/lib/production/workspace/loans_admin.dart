import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'actions.dart';
import 'chrome.dart';
import 'dashboard.dart';
import 'swipe_approve.dart';

/// Status groups for the admin filter: key, label, statuses.
const _openGroups = <(String, String, List<String>)>[
  ('pending', 'Menunggu', ['pending']),
  ('approved', 'Siap diambil', ['approved']),
  ('borrowed', 'Dipinjam', ['borrowed', 'overdue']),
  ('returning', 'Perlu diperiksa', ['returning', 'needs_review']),
];
const _closedGroups = <(String, String, List<String>)>[
  ('returned', 'Selesai', ['returned']),
  ('rejected', 'Ditolak', ['rejected']),
  ('cancelled', 'Dibatalkan', ['cancelled']),
];

/// Admin 'Pinjaman' (every loan) and 'Riwayat' (closed loans).
class AdminLoans extends StatelessWidget {
  const AdminLoans({
    required this.actions,
    required this.history,
    required this.filter,
    required this.onFilter,
    super.key,
  });
  final WorkspaceActions actions;
  final bool history;
  final String filter;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    final loans = actions.app.loans
        .where((loan) => history ? loan.closed : true)
        .toList();
    final groups = history ? _closedGroups : _openGroups;
    int count(List<String> statuses) =>
        loans.where((l) => statuses.contains(l.status)).length;
    final selected = groups.where((g) => g.$1 == filter).firstOrNull;
    final rows = selected == null
        ? loans
        : loans.where((l) => selected.$3.contains(l.status)).toList();
    final late = loans.where((l) => l.late).length;
    final summary = [
      for (final group in groups)
        '${count(group.$3)} ${group.$2.toLowerCase()}',
      if (!history && late > 0) '$late terlambat',
    ].join(' · ');
    return SectionLayout(
      title: history ? 'Riwayat' : 'Pinjaman',
      extra: Text(
        summary,
        style: const TextStyle(color: AppColors.navyMuted, fontSize: 14),
      ),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('Semua', 'Semua', loans.length),
              for (final group in groups)
                _chip(group.$1, group.$2, count(group.$3)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const StateMessage(
            title: 'Daftar kosong',
            message: 'Belum ada pinjaman pada daftar ini.',
            icon: Icons.inbox_outlined,
          ),
        for (var i = 0; i < rows.length; i++)
          Padding(
            key: ValueKey(rows[i].id),
            padding: const EdgeInsets.only(bottom: 12),
            child: SpringReveal(
              index: i,
              child: QueueCard(actions: actions, loan: rows[i]),
            ),
          ),
        if (rows.any((Loan l) => l.status == 'pending')) const SwipeHint(),
      ],
    );
  }

  Widget _chip(String key, String label, int count) {
    final active = filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label $count'),
        selected: active,
        labelStyle: TextStyle(
          color: active ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onFilter(key),
      ),
    );
  }
}
