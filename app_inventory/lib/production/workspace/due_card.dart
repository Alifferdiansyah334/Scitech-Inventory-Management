import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/progress.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import '../catalog/dates.dart';
import 'loan_card.dart';

/// Whether an in-use loan's return is late or at most two days away: the
/// point from which 'Pinjaman' shows it as its hero.
bool loanDueSoon(Loan loan) => loan.late || daysUntil(loan.dueDate) <= 2;

/// The return that is due or late, as the hero of 'Pinjaman': a big
/// countdown, the due date, time used as a wavy bar, the item and the next
/// actions. Deadline orange from two days before the return date, error
/// colours once late; hero colours when shown earlier than that.
class DueCard extends StatelessWidget {
  const DueCard({required this.loan, required this.onReturn, required this.onContact, this.category = '', super.key});
  final Loan loan;
  final VoidCallback? onReturn, onContact;

  /// Category of the loaned item, for its shape.
  final String category;

  @override
  Widget build(BuildContext context) {
    final days = daysUntil(loan.dueDate);
    final late = loan.late || days < 0;
    final soon = !late && days <= 2;
    final count = late ? (days < 0 ? -days : 1) : days;
    final deadline = late
        ? 'Terlambat $count hari'
        : days == 0
        ? 'Kembali hari ini'
        : 'Kembali dalam $count hari';
    final (bg, on, accent, track, soft) = late
        ? (
            AppColors.errorContainer,
            AppColors.onErrorContainer,
            AppColors.error,
            AppColors.error.withValues(alpha: .3),
            AppColors.error.withValues(alpha: .12),
          )
        : soon
        ? (
            AppColors.deadlineContainer,
            AppColors.onDeadlineContainer,
            AppColors.deadline,
            AppColors.deadlineTrack,
            AppColors.deadlineTrack.withValues(alpha: .45),
          )
        : (
            AppColors.hero,
            AppColors.onHero,
            AppColors.onHero,
            AppColors.onHero.withValues(alpha: .28),
            AppColors.heroSoft,
          );
    final backdrop = late
        ? ExpressiveShape.burst
        : soon
        ? ExpressiveShape.sunny8
        : ExpressiveShape.cookie12;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            top: -56,
            end: -48,
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: 200,
                child: DecoratedBox(
                  decoration: ShapeDecoration(color: soft, shape: ExpressiveShapeBorder(backdrop, rotation: .3)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: '$deadline, ${dayDate(loan.dueDate)} pukul ${clockTime(loan.dueDate)}',
                        excludeSemantics: true,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final countdown = _countdown(late, days, count, on);
                            final date = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dayDate(loan.dueDate),
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: on),
                                ),
                                Text(
                                  'pukul ${clockTime(loan.dueDate)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: accent,
                                    fontFeatures: tabular,
                                  ),
                                ),
                              ],
                            );
                            if (box.maxWidth < 520 || MediaQuery.textScalerOf(context).scale(16) > 20) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [countdown, const SizedBox(height: 16), date],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: countdown),
                                const SizedBox(width: 20),
                                Flexible(child: date),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      WavyLinearProgress(
                        value: loanElapsed(loan),
                        color: accent,
                        trackColor: track,
                        semanticsLabel: 'Waktu pinjam berjalan',
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dipinjam ${dayDate(loan.borrowDate)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: on),
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Flexible(
                            child: Text(
                              'Batas ${dayDate(loan.dueDate)}',
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _item(Theme.of(context).textTheme),
                const SizedBox(height: AppSpace.sm),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, box) {
                    final back = FilledButton.icon(
                      onPressed: onReturn,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Kembalikan', textAlign: TextAlign.center),
                    );
                    final contact = OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: on,
                        side: BorderSide(color: on.withValues(alpha: .4)),
                      ),
                      onPressed: onContact,
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Hubungi admin', textAlign: TextAlign.center),
                    );
                    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                    if (box.maxWidth < 420 * scale) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          back,
                          const SizedBox(height: AppSpace.sm),
                          contact,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: back),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(child: contact),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The loaned item on a white inset card.
  Widget _item(TextTheme text) => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadii.xl)),
    child: Row(
      children: [
        ShapeIcon.category(category, size: 56),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loan.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                '${loan.quantity} unit · ID ${shortId(loan.itemId)}',
                style: text.bodyMedium?.copyWith(color: AppColors.muted, fontFeatures: tabular),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// "Kembali dalam / 2 hari", "Terlambat / 3 hari" or "Batas kembali /
  /// Hari ini" with the number as the focal figure.
  Widget _countdown(bool late, int days, int count, Color on) {
    final label = late
        ? 'Terlambat'
        : days == 0
        ? 'Batas kembali'
        : 'Kembali dalam';
    final big = TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 72,
      fontWeight: FontWeight.w800,
      letterSpacing: -2,
      height: 1,
      color: on,
      fontFeatures: tabular,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: on),
        ),
        const SizedBox(height: 4),
        !late && days == 0
            ? Text('Hari ini', style: big.copyWith(fontSize: 40, letterSpacing: -0.8))
            : Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$count'),
                    TextSpan(
                      text: ' hari',
                      style: TextStyle(
                        fontFamily: AppFonts.sans,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                style: big,
              ),
      ],
    );
  }
}
