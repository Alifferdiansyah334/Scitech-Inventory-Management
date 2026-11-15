import 'package:flutter/material.dart';
import '../../ui/button_feedback.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import '../catalog/dates.dart';
import 'choice_card.dart';
import 'request_parts.dart';

const loanDayOptions = [1, 3, 7, 14, 30];

/// Each preset keeps one shape; the card turns it when picked.
const _optionShapes = [
  ExpressiveShape.circle,
  ExpressiveShape.cookie9,
  ExpressiveShape.sunny8,
  ExpressiveShape.clover4,
  ExpressiveShape.flower8,
];

/// Lama pinjam: one selectable card per preset with its return day. None is
/// selected once a custom return date is picked.
class DurationSection extends StatelessWidget {
  const DurationSection({
    required this.days,
    required this.custom,
    required this.busy,
    required this.onDays,
    super.key,
  });
  final int days;
  final bool custom, busy;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ChoiceGrid(
      children: [
        for (var i = 0; i < loanDayOptions.length; i++)
          ChoiceCard(
            title: '${loanDayOptions[i]} hari',
            subtitle: 'Kembali ${dayDate(now.add(Duration(days: loanDayOptions[i])))}',
            icon: Icons.schedule_rounded,
            shape: _optionShapes[i],
            selected: !custom && loanDayOptions[i] == days,
            onTap: busy ? null : () => onDays(loanDayOptions[i]),
          ),
      ],
    );
  }
}

/// Custom return date under the durations: the computed or picked date on a
/// white card that opens the date picker; picked, it takes the selected
/// fill like the duration cards.
class ReturnDateRow extends StatelessWidget {
  const ReturnDateRow({
    required this.due,
    required this.custom,
    required this.busy,
    required this.onPickDate,
    super.key,
  });
  final DateTime due;
  final bool custom, busy;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(custom ? 16 : 24));
    return Semantics(
      button: true,
      label: 'Tanggal kembali ${longDate(due)}, ketuk untuk ubah',
      excludeSemantics: true,
      onTap: tactileTap(busy ? null : onPickDate),
      child: PressSpring(
        enabled: !busy,
        scale: .98,
        squash: .04,
        child: Material(
          color: custom ? AppColors.secondary : AppColors.card,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: shape,
            onTap: tactileTap(busy ? null : onPickDate),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                child: Row(
                  children: [
                    ShapeIcon(
                      icon: Icons.event_rounded,
                      shape: ExpressiveShape.cookie12,
                      size: 40,
                      fill: custom ? AppColors.brand : AppColors.secondary,
                      foreground: custom ? AppColors.onBrand : AppColors.onSecondary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            custom ? 'Tanggal pilihan' : 'Tanggal kembali',
                            style: text.labelMedium?.copyWith(color: AppColors.muted),
                          ),
                          Text(longDate(due), style: text.titleSmall?.copyWith(fontFeatures: tabular)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ubah',
                      style: text.labelLarge?.copyWith(color: busy ? AppColors.onDisabled : AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
