import 'package:flutter/material.dart';
import '../../models.dart';
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

/// Navy circle with a person's initials.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.name, {this.size = 40, super.key});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    ),
  );
}

/// A colleague's active loan: who, which team, which item, when it returns.
class TeamLoanTile extends StatelessWidget {
  const TeamLoanTile({
    required this.loan,
    this.color = AppColors.surface,
    super.key,
  });
  final TeamLoan loan;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(loan.borrowerName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${loan.borrowerName}${loan.isMine ? ' (Anda)' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (loan.department.isNotEmpty)
                Text(
                  loan.department,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              const SizedBox(height: 8),
              Text(
                '${loan.itemName} · ${loan.quantity} unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${statusLabels[loan.status] ?? loan.status} · kembali ${dayDate(loan.dueDate)}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
