import 'package:flutter/material.dart';
import '../core/password_policy.dart';
import '../ui/springs.dart';
import '../ui/tokens.dart';

/// Strength bar (four segments) plus either a compact hint naming the
/// missing rules or the full rules checklist computed by [PasswordPolicy].
/// Pass [confirmation] to add a "both passwords match" rule.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({
    required this.controller,
    this.confirmation,
    this.rules = true,
    super.key,
  });
  final TextEditingController controller;
  final TextEditingController? confirmation;
  final bool rules;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, ?confirmation]),
    builder: (context, child) {
      final text = controller.text;
      final policy = PasswordPolicy(text);
      final filled = text.isEmpty
          ? 0
          : !policy.valid
          ? (policy.score >= 3 ? 2 : 1)
          : policy.strength == 'Sedang'
          ? 3
          : 4;
      final color = policy.valid ? AppColors.ok : AppColors.bad;
      final requirements = <(bool, String)>[
        (policy.longEnough, 'Minimal 8 karakter'),
        (policy.uppercase, 'Huruf besar (A–Z)'),
        (policy.lowercase, 'Huruf kecil (a–z)'),
        (policy.number, 'Angka (0–9)'),
        (policy.symbol, 'Simbol (!@# dan lainnya)'),
        if (confirmation case final other?)
          (
            text.isNotEmpty && other.text == text,
            'Kedua kata sandi sama',
          ),
      ];
      final missing = [
        if (!policy.longEnough) 'minimal 8 karakter',
        if (!policy.uppercase) 'huruf besar',
        if (!policy.lowercase) 'huruf kecil',
        if (!policy.number) 'angka',
        if (!policy.symbol) 'simbol',
      ];
      final duration = reducedMotion(context)
          ? Duration.zero
          : snappyCurve.duration;
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: duration,
                      curve: snappyCurve,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < filled ? color : AppColors.paper,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text.isEmpty
                  ? 'Kekuatan kata sandi'
                  : 'Kekuatan kata sandi: ${policy.strength}',
              style: TextStyle(
                fontSize: 13,
                color: text.isEmpty ? AppColors.muted : color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!rules && text.isNotEmpty && missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Tambahkan ${missing.join(', ')}.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            if (!rules && text.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Gunakan 8–128 karakter dengan huruf besar, huruf kecil, '
                  'angka, dan simbol.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            if (rules) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (met, label) in requirements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              met ? Icons.check_circle : Icons.circle_outlined,
                              size: 20,
                              color: met ? AppColors.ok : AppColors.control,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                met ? label : '$label (belum)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: met ? AppColors.ink : AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
