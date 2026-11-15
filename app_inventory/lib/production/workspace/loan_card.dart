import 'package:flutter/material.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/progress.dart';

/// Stage progress of an open loan (pending to returned).
double loanProgress(Loan loan) =>
    const {
      'pending': .15,
      'approved': .35,
      'borrowed': .6,
      'overdue': .6,
      'returning': .85,
      'needs_review': .85,
    }[loan.status] ??
    0;

/// Share of the loan period already used (pick-up to return date), 0–1.
double loanElapsed(Loan loan) {
  final span = loan.dueDate.difference(loan.borrowDate).inMinutes;
  if (span <= 0) return 1;
  return (DateTime.now().difference(loan.borrowDate).inMinutes / span).clamp(0.0, 1.0).toDouble();
}

/// Whole days between pick-up and return (at least one).
int loanDays(Loan loan) {
  final days = DateUtils.dateOnly(loan.dueDate).difference(DateUtils.dateOnly(loan.borrowDate)).inDays;
  return days < 1 ? 1 : days;
}

/// Stage of an open loan as a wavy bar coloured by the loan's tone.
class LoanStageBar extends StatelessWidget {
  const LoanStageBar(this.loan, {super.key});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final tone = toneColors(loanTone(loan.status, late: loan.late));
    return WavyLinearProgress(
      value: loanProgress(loan),
      color: tone.fg,
      trackColor: tone.bg,
      semanticsLabel: 'Tahap pinjaman',
    );
  }
}
