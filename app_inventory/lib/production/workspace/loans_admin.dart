import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../catalog/dates.dart';
import 'actions.dart';
import 'admin_rows.dart';
import 'chrome.dart';
import 'queue_detail.dart';
import 'queue_strip.dart';
import 'swipe_approve.dart';

/// One admin filter: key (as passed by [AdminLoans.filter]), its count card
/// and which loans it keeps.
typedef _Group = ({
  String key,
  String label,
  Tone tone,
  IconData icon,
  ExpressiveShape shape,
  bool Function(Loan) test,
});

bool _late(Loan l) => l.late || l.status == 'overdue';

final _openGroups = <_Group>[
  (
    key: 'pending',
    label: 'Menunggu',
    tone: Tone.waiting,
    icon: Icons.schedule_rounded,
    shape: ExpressiveShape.sunny8,
    test: (l) => l.status == 'pending',
  ),
  (
    key: 'approved',
    label: 'Siap diambil',
    tone: Tone.ok,
    icon: Icons.check_rounded,
    shape: ExpressiveShape.flower8,
    test: (l) => l.status == 'approved',
  ),
  (
    key: 'borrowed',
    label: 'Dipinjam',
    tone: Tone.info,
    icon: Icons.outbox_outlined,
    shape: ExpressiveShape.cookie9,
    test: (l) => const ['borrowed', 'overdue'].contains(l.status) && !_late(l),
  ),
  (
    key: 'late',
    label: 'Terlambat',
    tone: Tone.bad,
    icon: Icons.priority_high_rounded,
    shape: ExpressiveShape.burst,
    test: (l) => !l.closed && _late(l),
  ),
  (
    key: 'returning',
    label: 'Perlu diperiksa',
    tone: Tone.waiting,
    icon: Icons.fact_check_outlined,
    shape: ExpressiveShape.softBurst,
    test: (l) => const ['returning', 'needs_review'].contains(l.status),
  ),
];

final _closedGroups = <_Group>[
  (
    key: 'returned',
    label: 'Selesai',
    tone: Tone.ok,
    icon: Icons.task_alt_rounded,
    shape: ExpressiveShape.flower8,
    test: (l) => l.status == 'returned',
  ),
  (
    key: 'rejected',
    label: 'Ditolak',
    tone: Tone.bad,
    icon: Icons.close_rounded,
    shape: ExpressiveShape.burst,
    test: (l) => l.status == 'rejected',
  ),
  (
    key: 'cancelled',
    label: 'Dibatalkan',
    tone: Tone.neutral,
    icon: Icons.block_rounded,
    shape: ExpressiveShape.cookie9,
    test: (l) => l.status == 'cancelled',
  ),
];

/// 'Hari ini', 'Kemarin', 'Besok' or the date (with the year when it is
/// not this year).
String _relativeDay(DateTime day) {
  final days = daysUntil(day);
  if (days == 0) return 'Hari ini';
  if (days == -1) return 'Kemarin';
  if (days == 1) return 'Besok';
  final label = dayDate(day);
  return day.year == DateTime.now().year ? label : '$label ${day.year}';
}

/// Admin 'Pinjaman' (every loan) and 'Riwayat' (closed loans) in the
/// AgroLens history recipe: title and subtitle, the connected count cards
/// as filters, then the loans grouped per pick-up day as history_item rows.
/// Phone: a row opens its detail in a sheet and pending rows swipe right to
/// approve. Wide: the selected loan's detail sits in the aside pane.
class AdminLoans extends StatefulWidget {
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
  State<AdminLoans> createState() => _AdminLoansState();
}

class _AdminLoansState extends State<AdminLoans> {
  String? selectedId;

  WorkspaceActions get actions => widget.actions;

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    final loans = actions.app.loans.where((loan) => history ? loan.closed : true).toList();
    final groups = history ? _closedGroups : _openGroups;
    final index = groups.indexWhere((g) => g.key == widget.filter);
    final rows = (index < 0 ? loans : loans.where(groups[index].test).toList())
      ..sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
    final days = <(DateTime, List<Loan>)>[];
    for (final loan in rows) {
      final day = DateUtils.dateOnly(loan.borrowDate);
      if (days.isEmpty || days.last.$1 != day) days.add((day, []));
      days.last.$2.add(loan);
    }
    final late = loans.where((l) => !l.closed && _late(l)).length;
    final wide = chromeWide(context);
    final selected = wide && rows.isNotEmpty ? rows.where((l) => l.id == selectedId).firstOrNull ?? rows.first : null;
    return SectionLayout(
      title: history ? 'Riwayat' : 'Pinjaman',
      extra: sectionSummary(
        context,
        [
          '${loans.length} ${history ? 'pinjaman selesai' : 'pinjaman'}',
          if (!history && late > 0) '$late terlambat',
        ].join(' · '),
      ),
      aside: selected == null
          ? null
          : Padding(
              key: ValueKey(selected.id),
              padding: const EdgeInsets.all(16),
              child: QueueDetail(actions: actions, loan: selected),
            ),
      children: [
        CountFilterGroup(
          filters: [
            CountFilter(
              label: 'Semua',
              count: loans.length,
              icon: Icons.grid_view_rounded,
              shape: ExpressiveShape.cookie9,
            ),
            for (final g in groups)
              CountFilter(
                label: g.label,
                count: loans.where(g.test).length,
                tone: g.tone,
                icon: g.icon,
                shape: g.shape,
              ),
          ],
          selected: index + 1,
          onSelect: (i) => widget.onFilter(i == 0 ? 'Semua' : groups[i - 1].key),
        ),
        if (rows.isEmpty)
          AdminEmpty(
            title: loans.isEmpty ? (history ? 'Belum ada riwayat' : 'Belum ada pinjaman') : 'Daftar kosong',
            message: loans.isEmpty
                ? (history
                      ? 'Pinjaman yang selesai, ditolak, atau dibatalkan akan tersimpan di sini.'
                      : 'Permintaan peminjaman baru akan muncul di sini.')
                : 'Belum ada pinjaman pada status ini.',
            icon: history ? Icons.history_rounded : Icons.inbox_outlined,
            action: index < 0
                ? null
                : OutlinedButton(onPressed: () => widget.onFilter('Semua'), child: const Text('Tampilkan semua')),
          )
        else
          for (final (day, list) in days) ...[
            _DayHeader(_relativeDay(day)),
            AdminGrid(
              children: [for (final loan in list) _row(loan, master: wide, selected: loan.id == selected?.id)],
            ),
          ],
        if (rows.any((Loan l) => l.status == 'pending')) const SwipeHint(),
        const SizedBox(height: AppSpace.xl),
      ],
    );
  }

  /// History row; pending requests can be swiped right to approve.
  Widget _row(Loan loan, {required bool master, required bool selected}) {
    final row = QueueRow(
      actions: actions,
      loan: loan,
      selected: selected,
      onTap: master ? () => setState(() => selectedId = loan.id) : () => showQueueSheet(context, actions, loan.id),
    );
    if (loan.status != 'pending') {
      return KeyedSubtree(key: ValueKey(loan.id), child: row);
    }
    return SwipeToApprove(
      key: ValueKey(loan.id),
      enabled: !actions.locked,
      onApprove: () => actions.approve(loan),
      child: row,
    );
  }
}

/// Day heading above a group of rows (AgroLens history: labelLarge, muted).
class _DayHeader extends StatelessWidget {
  const _DayHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Semantics(
      header: true,
      child: Text(title, style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
    ),
  );
}
