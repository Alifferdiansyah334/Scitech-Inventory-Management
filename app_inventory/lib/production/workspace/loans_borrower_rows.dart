part of 'loans_borrower.dart';

/// Muted day header above a group of rows.
class _DayHeader extends StatelessWidget {
  const _DayHeader(this.title, {this.top = 24});
  final String title;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 4, 10),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.muted)),
    ),
  );
}

/// Rows 8 px apart: one column on phones, two where there is room.
class _RowGrid extends StatelessWidget {
  const _RowGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = AppSpace.sm;
      final width = box.maxWidth >= 720 ? (box.maxWidth - gap) / 2 : box.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

enum _EmptyView { own, team, history }

/// No loans in this view (AgroLens history_empty): a flower shape of 112
/// that can be flung around, a title, a short explanation and the way to
/// the catalogue.
class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans({required this.view, required this.onCatalog});
  final _EmptyView view;
  final VoidCallback onCatalog;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (icon, title, message) = switch (view) {
      _EmptyView.own => (
        Icons.inventory_2_outlined,
        'Belum ada pinjaman',
        'Pilih barang di katalog lalu ajukan peminjaman. Statusnya bisa dipantau di sini.',
      ),
      _EmptyView.team => (
        Icons.groups_outlined,
        'Tidak ada pinjaman rekan',
        'Belum ada barang yang sedang dipinjam rekan.',
      ),
      _EmptyView.history => (
        Icons.history_rounded,
        'Riwayat masih kosong',
        'Pinjaman yang sudah kembali, ditolak, atau dibatalkan akan tersimpan di sini.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
      child: Column(
        children: [
          SpringDraggable(
            reach: 110,
            child: ShapeIcon(
              icon: icon,
              shape: ExpressiveShape.flower8,
              size: 112,
              fill: AppColors.secondary,
              foreground: AppColors.onSecondary,
              iconScale: .4,
            ),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: text.titleLarge),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCatalog,
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text('Jelajahi katalog'),
          ),
        ],
      ),
    );
  }
}

/// Own loans, colleagues' loans and history as a connected button group
/// (AgroLens expressive choice; the page title already says 'Pinjaman').
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.view, required this.onView});
  final String view;
  final ValueChanged<String> onView;

  @override
  Widget build(BuildContext context) {
    final grow = (MediaQuery.textScalerOf(context).scale(14) / 14 - 1).clamp(0.0, 2.0);
    // Three options at phone width: badge above the label (AgroLens Tema
    // group, vertical: true) so the labels keep their full width.
    return ExpressiveButtonGroup<String>(
      height: 96 + 30 * grow,
      vertical: true,
      selected: const ['Pinjaman saya', 'Pinjaman rekan', 'Riwayat'].contains(view) ? view : 'Pinjaman saya',
      onChanged: onView,
      segments: const [
        ExpressiveSegment(
          value: 'Pinjaman saya',
          label: 'Milik saya',
          icon: Icons.inventory_2_outlined,
          shape: ExpressiveShape.cookie9,
        ),
        ExpressiveSegment(
          value: 'Pinjaman rekan',
          label: 'Rekan',
          icon: Icons.groups_outlined,
          shape: ExpressiveShape.clover4,
        ),
        ExpressiveSegment(
          value: 'Riwayat',
          label: 'Riwayat',
          icon: Icons.history_rounded,
          shape: ExpressiveShape.sunny8,
        ),
      ],
    );
  }
}

/// A colleague's active loan as a white history row: their initials in a
/// shape, the item on one line, who and when, the status pill.
class _TeamLoanCard extends StatelessWidget {
  const _TeamLoanCard({required this.loan});
  final TeamLoan loan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final who =
        '${loan.borrowerName}${loan.isMine ? ' (Anda)' : ''}'
        '${loan.department.isEmpty ? '' : ' · ${loan.department}'}';
    final status = statusLabels[loan.status] ?? loan.status;
    return Semantics(
      label: '${loan.itemName}, ${loan.quantity} unit, dipakai $who, $status, kembali ${dayDate(loan.dueDate)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            ShapeIcon(
              icon: Icons.person_rounded,
              shape: ExpressiveShape.cookie12,
              size: 60,
              fill: AppColors.secondary,
              foreground: AppColors.onSecondary,
              iconScale: .45,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(who, style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                  Text(
                    '${loan.quantity} unit · kembali ${dayDate(loan.dueDate)}',
                    style: text.bodySmall?.copyWith(color: AppColors.muted, fontFeatures: tabular),
                  ),
                  const SizedBox(height: 6),
                  StatusPill(status, tone: loanTone(loan.status), dense: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
