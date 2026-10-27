import 'package:flutter/material.dart';
import '../core/password_policy.dart';

class PasswordStrength extends StatelessWidget {
  const PasswordStrength({required this.controller, super.key});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          final policy = PasswordPolicy(value.text);
          final color = !policy.valid
              ? Colors.red.shade700
              : policy.strength == 'Sedang'
              ? Colors.orange.shade800
              : Colors.teal.shade700;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.text.isEmpty
                      ? 'Kekuatan kata sandi'
                      : 'Kekuatan kata sandi: ${policy.strength}',
                  style: TextStyle(
                    color: value.text.isEmpty ? Colors.blueGrey : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: value.text.isEmpty
                      ? 0
                      : !policy.valid
                      ? policy.score / 6
                      : policy.strength == 'Sedang'
                      ? .75
                      : 1,
                  color: color,
                  backgroundColor: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 5,
                ),
                const SizedBox(height: 10),
                for (final requirement in <(bool, String)>[
                  (policy.longEnough, 'Minimal 8 karakter'),
                  (policy.uppercase, 'Huruf besar (A–Z)'),
                  (policy.lowercase, 'Huruf kecil (a–z)'),
                  (policy.number, 'Angka (0–9)'),
                  (policy.symbol, 'Simbol (!@# dan lainnya)'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(
                          requirement.$1
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 15,
                          color: requirement.$1
                              ? Colors.teal.shade700
                              : Colors.blueGrey,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            requirement.$2,
                            style: TextStyle(
                              fontSize: 12,
                              color: requirement.$1
                                  ? Colors.teal.shade700
                                  : Colors.blueGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
}
