import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/controls.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../catalog/dates.dart';
import 'actions.dart';
import 'chrome.dart';
import 'due_card.dart';
import 'loan_filter.dart';
import 'loan_sheet.dart';

part 'loans_borrower_rows.dart';

/// Filter card of an open loan: waiting on someone, running, or late.
String _openBucket(Loan l) => l.late || l.status == 'overdue'
    ? 'late'
    : const ['approved', 'borrowed'].contains(l.status)
    ? 'running'
    : 'waiting';

const _openFilters = [
  ('waiting', 'Menunggu', Tone.waiting),
  ('running', 'Berjalan', Tone.info),
  ('late', 'Terlambat', Tone.bad),
];
const _closedFilters = [('returned', Tone.ok), ('rejected', Tone.bad), ('cancelled', Tone.neutral)];

/// Borrower 'Pinjaman' (AgroLens history tab): title with the 'Pinjam'
/// pill, own / colleagues' / past loans as a connected button group, the return that
/// is due or late as the page's hero ([DueCard]), tall count cards that
/// filter by status, then the loans as white rows under day headers.
class BorrowerLoans extends StatelessWidget {
  const BorrowerLoans({
    required this.actions,
    required this.view,
    required this.filter,
    required this.onView,
    required this.onFilter,
    required this.onCatalog,
    super.key,
  });
  final WorkspaceActions actions;
  final String view, filter;
  final ValueChanged<String> onView, onFilter;
  final VoidCallback onCatalog;

  bool _matches(Loan l, bool history) => filter == 'Semua' || (history ? l.status == filter : _openBucket(l) == filter);

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final history = view == 'Riwayat', team = view == 'Pinjaman rekan';
    final scope = app.loans.where((l) => l.closed == history).toList();
    final rows = scope.where((l) => _matches(l, history)).toList();
    final due = rows.where((l) => loanInUse(l) && loanDueSoon(l)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final focal = team || history ? null : due.firstOrNull;
    final tabs = _ScopeTabs(view: view, onView: onView);
    return SectionLayout(
      title: 'Pinjaman',
      extra: const Text('Pinjaman Anda dan tim'),
      titleTrailing: app.loans.isEmpty
          ? null
          : PillAction(
              label: 'Pinjam',
              icon: Icons.inventory_2_rounded,
              shape: ExpressiveShape.cookie12,
              onPressed: onCatalog,
            ),
      children: [
        if (chromeWide(context))
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: tabs),
          )
        else
          tabs,
        const SizedBox(height: 20),
        if (focal != null) ...[
          DueCard(
            loan: focal,
            category: app.items.where((i) => i.id == focal.itemId).firstOrNull?.category ?? '',
            onReturn: actions.locked ? null : () => actions.photoAction(focal, true),
            onContact: app.adminContacts.isEmpty ? null : () => actions.contactAdmin(focal),
          ),
          const SizedBox(height: AppSpace.xl),
        ],
        if (team)
          ..._team(app.activity)
        else if (scope.isEmpty)
          _EmptyLoans(view: history ? _EmptyView.history : _EmptyView.own, onCatalog: onCatalog)
        else
          ..._own(context, scope, rows.where((l) => l != focal).toList(), history),
      ],
    );
  }

  List<Widget> _team(List<TeamLoan> activity) {
    final colleagues = activity.where((l) => !l.isMine).toList();
    if (colleagues.isEmpty) {
      return [_EmptyLoans(view: _EmptyView.team, onCatalog: onCatalog)];
    }
    return [
      _DayHeader('Sedang dipinjam rekan', top: 0),
      _RowGrid(
        children: [
          for (final (i, loan) in colleagues.indexed)
            Reveal(
              key: ValueKey(loan.id),
              index: i.clamp(0, 6),
              child: _TeamLoanCard(loan: loan),
            ),
        ],
      ),
    ];
  }

  /// 'Semua' plus one card per status group, each counting the loans it
  /// shows (all of them add up to 'Semua').
  List<LoanFilterOption> _options(List<Loan> scope, bool history) => [
    (key: 'Semua', label: 'Semua', count: scope.length, tone: null),
    if (history)
      for (final (status, tone) in _closedFilters)
        (
          key: status,
          label: statusLabels[status] ?? status,
          count: scope.where((l) => l.status == status).length,
          tone: tone,
        )
    else
      for (final (key, label, tone) in _openFilters)
        (key: key, label: label, count: scope.where((l) => _openBucket(l) == key).length, tone: tone),
  ];

  List<Widget> _own(BuildContext context, List<Loan> scope, List<Loan> rows, bool history) {
    final sorted = [...rows]..sort((a, b) => b.borrowDate.compareTo(a.borrowDate));
    final groups = <(DateTime, List<Loan>)>[];
    for (final loan in sorted) {
      final day = DateUtils.dateOnly(loan.borrowDate);
      if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
      groups.last.$2.add(loan);
    }
    var index = 0;
    return [
      LoanCountFilter(options: _options(scope, history), selected: filter, onChanged: onFilter),
      if (sorted.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          child: Text(
            history ? 'Belum ada riwayat pada status ini.' : 'Belum ada pinjaman pada status ini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          ),
        ),
      for (final (day, loans) in groups) ...[
        _DayHeader(_relativeDay(day)),
        _RowGrid(
          children: [
            for (final loan in loans)
              Reveal(
                key: ValueKey(loan.id),
                index: (index++).clamp(0, 6),
                child: MyLoanCard(actions: actions, loan: loan),
              ),
          ],
        ),
      ],
    ];
  }
}

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
