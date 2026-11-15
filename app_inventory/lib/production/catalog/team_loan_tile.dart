import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import 'dates.dart';

/// Up to two initials from a person's name, '?' when empty.
String initialsOf(String name) {
  final letters = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
  return letters.isEmpty ? '?' : letters;
}

/// A person's initials in a soft cookie shape (AgroLens AuthorAvatar).
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {this.size = 44, super.key});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.colors.tertiaryContainer,
          shape: const ExpressiveShapeBorder(ExpressiveShape.cookie12),
        ),
        child: Center(
          child: Text(
            initialsOf(name),
            textScaler: TextScaler.noScaling,
            style: context.text.titleSmall?.copyWith(color: context.colors.onTertiaryContainer, fontSize: size * .34),
          ),
        ),
      ),
    ),
  );
}

/// A colleague's active loan in the AgroLens history item recipe: white
/// card radius 24 with padding 10, the person in a shape 60, who (one
/// line), what and until when (bodySmall) and the status pill.
class TeamLoanTile extends StatelessWidget {
  const TeamLoanTile({required this.loan, this.showItem = true, super.key});
  final TeamLoan loan;

  /// Names the item in the meta line; off on the item's own page.
  final bool showItem;

  @override
  Widget build(BuildContext context) {
    final who = '${loan.borrowerName}${loan.isMine ? ' (Anda)' : ''}';
    final status = statusLabels[loan.status] ?? loan.status;
    final large = MediaQuery.textScalerOf(context).scale(16) > 20;
    return Semantics(
      label:
          '${loan.itemName}, ${loan.quantity} unit, dipakai $who, '
          '$status, kembali ${dayDate(loan.dueDate)}',
      excludeSemantics: true,
      child: SurfaceCard(
        radius: 24,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            PersonAvatar(loan.borrowerName, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    who,
                    maxLines: large ? null : 1,
                    overflow: large ? null : TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (showItem) loan.itemName,
                      '${loan.quantity} unit',
                      if (loan.department.isNotEmpty) loan.department,
                      'kembali ${dayDate(loan.dueDate)}',
                    ].join(' · '),
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontFeatures: tabular,
                    ),
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
