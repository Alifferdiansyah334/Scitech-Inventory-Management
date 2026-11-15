import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/physics.dart';
import '../../ui/progress.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../catalog/dates.dart';
import 'actions.dart';
import 'admin_rows.dart';
import 'loan_details.dart';

/// Loaned item's picture clipped to its category shape (AgroLens crop
/// photo), or the category shape and icon when the item has no photo.
class LoanThumb extends StatelessWidget {
  const LoanThumb({required this.actions, required this.loan, this.size = 60, super.key});
  final WorkspaceActions actions;
  final Loan loan;
  final double size;

  @override
  Widget build(BuildContext context) {
    final item = actions.app.items.where((i) => i.id == loan.itemId).firstOrNull;
    return ShapedThumb(
      category: item?.category ?? '',
      imageUrl: item?.imageUrl ?? '',
      picture: actions.picture,
      size: size,
    );
  }
}

/// One loan as an AgroLens history_item: white card radius 24, padding 10,
/// the 60 shaped picture, a one-line title, one muted meta line, a dense
/// status pill and the 34 arrow badge. Pending requests also say how much
/// stock approval leaves. [selected] tints the row (wide master-detail).
class QueueRow extends StatelessWidget {
  const QueueRow({required this.actions, required this.loan, required this.onTap, this.selected = false, super.key});
  final WorkspaceActions actions;
  final Loan loan;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    final item = actions.app.items.where((i) => i.id == loan.itemId).firstOrNull;
    final who = loan.borrower.isEmpty ? 'Peminjam' : loan.borrower;
    final after = item == null ? null : item.available - loan.quantity;
    final stock = loan.status == 'pending' && after != null
        ? (after < 0 ? 'kurang ${-after} unit' : 'sisa $after dari ${item!.total}')
        : null;
    final short = after != null && after <= 0;
    final meta = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: tabular);
    return SurfaceCard(
      selected: selected,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          LoanThumb(actions: actions, loan: loan),
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
                Text('$who · ${loan.quantity} unit · kembali ${dayDate(loan.dueDate)}', style: meta),
                if (stock != null)
                  Text(
                    'Stok $stock',
                    style: meta?.copyWith(
                      color: short ? AppColors.deadline : null,
                      fontWeight: short ? FontWeight.w600 : null,
                    ),
                  ),
                const SizedBox(height: 6),
                StatusPill(loan.label, tone: loanTone(loan.status, late: loan.late), dense: true),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ShapeIcon(
            icon: Icons.arrow_forward_rounded,
            shape: ExpressiveShape.cookie9,
            size: 34,
            fill: selected ? AppColors.card : scheme.surfaceContainerHighest,
            foreground: scheme.primary,
            iconScale: .5,
          ),
        ],
      ),
    );
  }
}

/// Everything an admin needs to decide one request, in the AgroLens result
/// body: the verdict card (status pill, item, borrower and dates; a wavy
/// ring counting the item's ready stock), then the loan details as a
/// section and the actions.
class QueueDetail extends StatelessWidget {
  const QueueDetail({required this.actions, required this.loan, super.key});
  final WorkspaceActions actions;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final buttons = loanButtons(actions, loan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Reveal(
          child: TiltOnTouch(
            maxAngle: .05,
            child: _Verdict(actions: actions, loan: loan),
          ),
        ),
        const SectionTitle('Rincian pinjaman'),
        LoanDetails(actions: actions, loan: loan),
        if (buttons != null) ...[const SizedBox(height: AppSpace.xl), buttons],
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.actions, required this.loan});
  final WorkspaceActions actions;
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final item = actions.app.items.where((i) => i.id == loan.itemId).firstOrNull;
    final who = loan.borrower.isEmpty ? 'Peminjam' : loan.borrower;
    final ready = item == null || item.total <= 0 ? null : item.available.clamp(0, item.total);
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
        child: LayoutBuilder(
          builder: (context, box) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusPill(loan.label, tone: loanTone(loan.status, late: loan.late)),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(loan.name, style: context.text.headlineSmall?.copyWith(height: 1.15)),
                ),
                const SizedBox(height: 4),
                Text(
                  '$who · ${loan.quantity} unit',
                  style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  '${dayDate(loan.borrowDate)}, ${clockTime(loan.borrowDate)} – ${dayDate(loan.dueDate)}',
                  style: context.text.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: tabular),
                ),
              ],
            );
            if (ready == null) return copy;
            final ring = _StockRing(ready: ready, total: item!.total);
            final stacked = box.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(16) > 24;
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      copy,
                      const SizedBox(height: 16),
                      Center(child: ring),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 12),
                      ring,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

/// Wavy ring 96 that counts up to the item's ready units.
class _StockRing extends StatelessWidget {
  const _StockRing({required this.ready, required this.total});
  final int ready, total;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: reducedMotion(context) ? Duration.zero : slowSpatialCurve.duration * 1.6,
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => WavyRingProgress(
      value: v * ready / total,
      size: 96,
      semanticsLabel: 'Stok siap $ready dari $total unit',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(v * ready).round()}',
                  style: context.text.titleLarge?.copyWith(height: 1, fontFeatures: tabular),
                ),
                Text('siap', style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Phone: the same detail in a bottom sheet that follows live data, so the
/// actions update after approving, handing over or confirming.
Future<void> showQueueSheet(BuildContext context, WorkspaceActions actions, String loanId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      sheetAnimationStyle: sheetAnimation(context),
      constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * .92),
      builder: (context) => ListenableBuilder(
        listenable: actions.app,
        builder: (context, _) {
          final loan = actions.app.loans.where((l) => l.id == loanId).firstOrNull;
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: loan == null
                  ? AdminEmpty(
                      title: 'Pinjaman tidak ditemukan',
                      message: 'Pinjaman ini sudah tidak ada di daftar. Tutup lembar ini dan pilih pinjaman lain.',
                      icon: Icons.inbox_outlined,
                      action: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                    )
                  : QueueDetail(actions: actions, loan: loan),
            ),
          );
        },
      ),
    );
