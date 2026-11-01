import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'request_parts.dart';

const loanDayOptions = [1, 3, 7, 14, 30];

/// Lama pinjam: preset durations on a segmented track whose navy thumb
/// springs to the selection, plus a custom return date picker.
class DurationCard extends StatelessWidget {
  const DurationCard({
    required this.days,
    required this.custom,
    required this.due,
    required this.busy,
    required this.onDays,
    required this.onPickDate,
    super.key,
  });
  final int days;
  final bool custom, busy;
  final DateTime due;
  final ValueChanged<int> onDays;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final index = custom ? -1 : loanDayOptions.indexOf(days);
    final reduced = reducedMotion(context);
    final duration = reduced ? Duration.zero : snappyCurve.duration;
    const fade = Duration(milliseconds: 180);
    return RequestCard(
      title: 'Lama pinjam',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: const ShapeDecoration(
              color: AppColors.paper,
              shape: StadiumBorder(),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedAlign(
                  alignment: Alignment(
                    index < 0
                        ? 0
                        : -1 + 2 * index / (loanDayOptions.length - 1),
                    0,
                  ),
                  duration: duration,
                  curve: snappyCurve,
                  child: FractionallySizedBox(
                    widthFactor: 1 / loanDayOptions.length,
                    heightFactor: 1,
                    child: AnimatedOpacity(
                      opacity: index < 0 ? 0 : 1,
                      duration: reduced ? Duration.zero : fade,
                      child: const DecoratedBox(
                        decoration: ShapeDecoration(
                          color: AppColors.navy,
                          shape: StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: Row(
                  children: [
                    for (final (i, d) in loanDayOptions.indexed)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == index,
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: busy ? null : () => onDays(d),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AnimatedDefaultTextStyle(
                                  duration: reduced ? Duration.zero : fade,
                                  style: TextStyle(
                                    fontFamily: AppFonts.sans,
                                    fontSize: 14,
                                    fontWeight: i == index
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: i == index
                                        ? Colors.white
                                        : AppColors.ink,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text('$d hari'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: busy ? null : onPickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kembali ${longDate(due)}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pilih tanggal',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
