part of 'otp_input.dart';

/// Cooldown is a noninteractive status, not a disabled-looking fake action.
/// Themed buttons retain native keyboard, focus, semantics and press feedback.
class OtpResend extends StatelessWidget {
  const OtpResend({required this.cooldown, required this.onResend, this.onChangeEmail, this.total = 60, super.key});
  final int cooldown, total;
  final VoidCallback? onResend, onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final clock = '${cooldown ~/ 60}:${(cooldown % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cooldown > 0)
            Semantics(
              label: 'Kirim ulang tersedia dalam $cooldown detik',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    WavyRingProgress(
                      value: total <= 0 ? 0 : (cooldown / total).clamp(0.0, 1.0),
                      size: 32,
                      strokeWidth: 3,
                      child: Icon(Icons.schedule_rounded, size: 18, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Kirim ulang dalam ',
                          children: [
                            TextSpan(
                              text: clock,
                              style: TextStyle(
                                fontFeatures: const [FontFeature.tabularFigures()],
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        style: context.text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            FilledButton.tonal(
              onPressed: onResend,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 10),
                    Flexible(child: Text('Kirim ulang kode', textAlign: TextAlign.center)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onChangeEmail,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Ubah email', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
