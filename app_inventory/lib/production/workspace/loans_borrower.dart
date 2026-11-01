import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../catalog/team_loan_tile.dart';
import 'actions.dart';
import 'chrome.dart';
import 'due_card.dart';
import 'loan_card.dart';

const _openStatuses = [
  'pending',
  'approved',
  'borrowed',
  'returning',
  'needs_review',
  'overdue',
];
const _closedStatuses = ['returned', 'rejected', 'cancelled'];

/// Borrower 'Pinjaman': own loans (nearest due on an accent card),
/// colleagues' loans and history.
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

  @override
  Widget build(BuildContext context) {
    final app = actions.app;
    final history = view == 'Riwayat', team = view == 'Pinjaman rekan';
    final rows = app.loans
        .where(
          (l) =>
              l.closed == history && (filter == 'Semua' || l.status == filter),
        )
        .toList();
    final inUse =
        rows
            .where((l) => const ['borrowed', 'overdue'].contains(l.status))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final focal = team || history ? null : inUse.firstOrNull;
    final others = rows.where((l) => l != focal).toList();
    return SectionLayout(
      title: 'Pinjaman',
      extra: _ScopeTabs(view: view, onView: onView),
      overlap: focal == null
          ? null
          : DueCard(
              loan: focal,
              onReturn: actions.locked
                  ? null
                  : () => actions.photoAction(focal, true),
              onContact: app.adminContacts.isEmpty
                  ? null
                  : () => actions.contactAdmin(focal),
            ),
      children: team ? _team(app.activity) : _own(others, history, focal),
    );
  }

  List<Widget> _team(List<TeamLoan> activity) {
    final colleagues = activity.where((l) => !l.isMine).toList();
    return [
      const SectionTitle('Barang yang sedang dipinjam rekan'),
      const Text(
        'Cek pemakai dan perkiraan kembali sebelum merencanakan peminjaman.',
        style: TextStyle(color: AppColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 14),
      if (colleagues.isEmpty)
        const StateMessage(
          title: 'Semua barang tersedia di tempat',
          message: 'Belum ada barang yang sedang dipinjam rekan.',
          icon: Icons.people_outline,
        ),
      for (var i = 0; i < colleagues.length; i++)
        SpringReveal(
          index: i,
          child: TeamLoanTile(loan: colleagues[i]),
        ),
    ];
  }

  List<Widget> _own(List<Loan> rows, bool history, Loan? focal) => [
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in [
            'Semua',
            ...history ? _closedStatuses : _openStatuses,
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(statusLabels[status] ?? status),
                selected: filter == status,
                labelStyle: TextStyle(
                  color: filter == status ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w500,
                ),
                onSelected: (_) => onFilter(status),
              ),
            ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    if (focal != null && rows.isNotEmpty) const SectionTitle('Lainnya'),
    if (rows.isEmpty && focal == null) ...[
      StateMessage(
        title: history ? 'Riwayat masih kosong' : 'Tidak ada pinjaman',
        message: history
            ? 'Belum ada riwayat pada status ini.'
            : 'Belum ada pinjaman pada status ini.',
        icon: history ? Icons.history : Icons.assignment_outlined,
        action: history
            ? null
            : OutlinedButton.icon(
                onPressed: onCatalog,
                icon: const Icon(Icons.grid_view),
                label: const Text('Jelajahi katalog'),
              ),
      ),
    ],
    for (var i = 0; i < rows.length; i++)
      Padding(
        key: ValueKey(rows[i].id),
        padding: const EdgeInsets.only(bottom: 12),
        child: SpringReveal(
          index: i,
          child: LoanCard(
            actions: actions,
            loan: rows[i],
            footer: rows[i].closed ? null : _progress(rows[i]),
          ),
        ),
      ),
  ];

  Widget _progress(Loan loan) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LoanStageBar(loan),
      const SizedBox(height: 8),
      Text(
        _loanHint(loan),
        style: const TextStyle(fontSize: 13, color: AppColors.muted),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: actions.app.adminContacts.isEmpty
              ? null
              : () => actions.contactAdmin(loan),
          icon: const Icon(Icons.chat_outlined, size: 17),
          label: const Text('Hubungi admin via WhatsApp'),
        ),
      ),
    ],
  );

  String _loanHint(Loan loan) => switch (loan.status) {
    'pending' => 'Pengajuan terkirim. Menunggu admin meninjau permintaan Anda.',
    'approved' =>
      'Pengajuan disetujui. Hubungi admin untuk pengambilan barang.',
    'borrowed' || 'overdue' =>
      'Barang sedang digunakan. Unggah foto kondisi ketika mengajukan pengembalian.',
    'returning' =>
      'Bukti pengembalian sudah terkirim. Menunggu pemeriksaan admin.',
    'needs_review' =>
      'Ada catatan pemeriksaan. Periksa catatan admin dan kirim ulang bukti.',
    _ => '',
  };
}

/// Segmented scope inside the navy header (active = white pill).
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.view, required this.onView});
  final String view;
  final ValueChanged<String> onView;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final tab in ['Pinjaman saya', 'Pinjaman rekan', 'Riwayat'])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tab),
              selected: view == tab,
              backgroundColor: AppColors.navy2,
              selectedColor: AppColors.surface,
              labelStyle: TextStyle(
                color: view == tab ? AppColors.navy : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onView(tab),
            ),
          ),
      ],
    ),
  );
}
