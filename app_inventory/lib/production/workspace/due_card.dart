import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../catalog/dates.dart';

/// Accent card for the borrower's nearest-due item in use: days left (or
/// late), due moment, item, stage, return and contact actions.
class DueCard extends StatelessWidget {
  const DueCard({
    required this.loan,
    required this.onReturn,
    required this.onContact,
    super.key,
  });
  final Loan loan;
  final VoidCallback? onReturn, onContact;

  @override
  Widget build(BuildContext context) {
    final days = daysUntil(loan.dueDate);
    final late = loan.late || days < 0;
    final count = late ? (days < 0 ? -days : 1) : days;
    final label = late
        ? 'Terlambat'
        : days == 0
        ? 'Kembali hari ini'
        : 'Kembali dalam';
    return Semantics(
      container: true,
      label: late
          ? 'Terlambat $count hari'
          : days == 0
          ? 'Kembali hari ini'
          : 'Kembali dalam $count hari',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        if (days != 0 || late)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  '$count',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 76,
                                    height: 1.05,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'hari',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AssetLabelCard(
                    title: 'ID ${shortId(loan.itemId)}',
                    subtitle: '${loan.quantity} unit',
                    angle: 0.06,
                    width: 140,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${dayDate(loan.dueDate)} · ${clockTime(loan.dueDate)}',
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              '${loan.name} · ${loan.quantity} unit',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
              ),
              onPressed: onReturn,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Ajukan pengembalian + foto'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.accentSoft,
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onContact,
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Hubungi admin via WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}
