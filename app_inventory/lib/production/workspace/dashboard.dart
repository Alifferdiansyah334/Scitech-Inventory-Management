import 'package:flutter/material.dart';
import '../../models.dart';
import '../../core/brand.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../home/home_header.dart';
import 'actions.dart';
import 'admin_rows.dart';
import 'chrome.dart';
import 'queue_detail.dart';
import 'queue_hero.dart';
import 'queue_strip.dart';
import 'swipe_approve.dart';

/// Admin 'Ringkasan' in the AgroLens home recipe (home_tab): greeting
/// header, the one queue hero (real pending count, queue box, 'Tinjau'),
/// count cards per status as filters (history_filter), then the queue as
/// history_item rows. Wide: the
/// selected request's detail sits in the aside pane. Phone: rows open the
/// detail in a sheet; pending rows can also be swiped right to approve.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({required this.actions, this.onOpenLoans, super.key});
  final WorkspaceActions actions;

  /// Opens 'Pinjaman' with a loans filter key ('pending', 'Semua', ...).
  final ValueChanged<String>? onOpenLoans;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _limit = 8;
  int? bucket;
  String? selectedId;

  WorkspaceActions get actions => widget.actions;

  /// Hero CTA: filters the queue to waiting requests and opens the oldest
  /// one (sheet on phones, the aside pane on wide layouts).
  void review(List<Loan> pending) {
    final first = pending.firstOrNull;
    setState(() {
      bucket = 0;
      selectedId = first?.id;
    });
    if (first != null && !chromeWide(context)) {
      showQueueSheet(context, actions, first.id);
    }
  }

  /// Opens one request: the aside pane on wide layouts, a sheet on phones.
  void open(Loan loan) {
    if (chromeWide(context)) {
      setState(() {
        bucket = queueBuckets.indexWhere((b) => b.test(loan)).clamp(0, queueBuckets.length - 1);
        selectedId = loan.id;
      });
    } else {
      showQueueSheet(context, actions, loan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final wide = chromeWide(context);
    final counts = [for (final b in queueBuckets) app.loans.where(b.test).length];
    final firstFilled = counts.indexWhere((c) => c > 0);
    final current = bucket ?? (firstFilled < 0 ? 0 : firstFilled);
    final group = queueBuckets[current];
    final rows = app.loans.where(group.test).toList();
    final shown = rows.take(_limit).toList();
    final selected = wide && shown.isNotEmpty
        ? shown.where((l) => l.id == selectedId).firstOrNull ?? shown.first
        : null;
    final openLoans = widget.onOpenLoans;
    final pending = app.loans.where(queueBuckets.first.test).toList();
    final body = <Widget>[
      QueueHero(
        actions: actions,
        pending: pending,
        late: counts[3],
        loading: app.loading && app.updatedAt == null,
        onOpen: open,
        onReview: pending.isNotEmpty
            ? () => review(pending)
            : openLoans == null
            ? null
            : () => openLoans('Semua'),
      ),
      const SizedBox(height: 16),
      CountFilterGroup(
        filters: [
          for (var i = 0; i < queueBuckets.length; i++)
            CountFilter(
              label: queueBuckets[i].label,
              count: counts[i],
              tone: queueBuckets[i].tone,
              icon: queueBuckets[i].icon,
              shape: queueBuckets[i].shape,
            ),
        ],
        selected: current,
        onSelect: (i) => setState(() {
          bucket = i;
          selectedId = null;
        }),
      ),
      SectionTitle(
        group.label,
        trailing: openLoans == null
            ? null
            : TextButton(onPressed: () => openLoans(group.loansFilter), child: const Text('Lihat semua')),
      ),
      if (shown.isEmpty)
        _empty(group)
      else
        for (final (i, loan) in shown.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _row(loan, master: wide, selected: loan.id == selected?.id),
        ],
      if (rows.length > shown.length)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, AppSpace.md, 4, 0),
          child: Text(
            '${shown.length} dari ${rows.length} ditampilkan',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted, fontFeatures: tabular),
          ),
        ),
      if (shown.any((l) => l.status == 'pending')) const SwipeHint(),
      const SizedBox(height: AppSpace.xl),
    ];
    if (wide) {
      return SectionLayout(title: 'Ringkasan', aside: selected == null ? null : _aside(selected), children: body);
    }
    final notice = WorkspaceChrome.maybeOf(context)?.notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeader(
          title: '$appName Admin',
          subtitle: (app.profile?.name.trim() ?? '').isEmpty
              ? null
              : '${greeting()}, ${app.profile!.name.trim().split(RegExp(r'\s+')).first}',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (notice != null) ...[notice, const SizedBox(height: AppSpace.lg)],
              // Hero and rows spring into place one after another (Reveal).
              for (final (i, child) in body.indexed)
                child is SizedBox ? child : Reveal(index: i < 6 ? i : 6, child: child),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aside(Loan loan) {
    final still = reducedMotion(context);
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 180),
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      child: Padding(
        key: ValueKey(loan.id),
        padding: const EdgeInsets.all(16),
        child: QueueDetail(actions: actions, loan: loan),
      ),
    );
  }

  Widget _empty(QueueBucket group) {
    final app = actions.app;
    if (app.loans.isEmpty && app.loading && app.updatedAt == null) {
      return const AdminEmpty(
        title: 'Memuat permintaan',
        message: 'Data pinjaman sedang diambil dari server.',
        icon: Icons.hourglass_empty_rounded,
      );
    }
    if (app.loans.isEmpty) {
      return AdminEmpty(
        title: 'Belum ada permintaan',
        message: 'Belum ada permintaan peminjaman. Permintaan baru akan muncul di sini.',
        icon: Icons.inbox_outlined,
        action: FilledButton.icon(
          onPressed: app.loading ? null : app.refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Perbarui data'),
        ),
      );
    }
    final open = widget.onOpenLoans;
    return AdminEmpty(
      title: 'Tidak ada yang perlu ditangani',
      message: group.empty,
      icon: Icons.task_alt,
      action: open == null
          ? null
          : OutlinedButton(onPressed: () => open('Semua'), child: const Text('Buka semua pinjaman')),
    );
  }

  Widget _row(Loan loan, {required bool master, bool selected = false}) {
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
