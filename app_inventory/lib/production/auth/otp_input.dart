import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// Six code boxes drawn behind one transparent [TextFormField], so paste,
/// autofill and validation keep working on a single field.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.controller,
    required this.enabled,
    this.onSubmitted,
    super.key,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const boxHeight = 58.0;
    final duration = reducedMotion(context)
        ? Duration.zero
        : snappyCurve.duration;
    const none = InputBorder.none;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const SizedBox(height: boxHeight, width: double.infinity),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: boxHeight,
            child: IgnorePointer(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  final text = value.text;
                  final active = text.length.clamp(0, 5);
                  return Row(
                    children: [
                      for (var i = 0; i < 6; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                            child: AnimatedContainer(
                              duration: duration,
                              curve: snappyCurve,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  width: 2,
                                  color: focus.hasFocus && i == active
                                      ? AppColors.navy
                                      : AppColors.paper,
                                ),
                              ),
                              child: Text(
                                i < text.length ? text[i] : '',
                                style: const TextStyle(
                                  fontFamily: AppFonts.mono,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          TextFormField(
            controller: widget.controller,
            focusNode: focus,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            showCursor: false,
            enableInteractiveSelection: false,
            onFieldSubmitted: (_) => widget.onSubmitted?.call(),
            style: const TextStyle(
              color: Colors.transparent,
              fontSize: 16,
              height: 1.25,
            ),
            decoration: const InputDecoration(
              filled: false,
              hintText: 'Kode OTP',
              hintStyle: TextStyle(color: Colors.transparent),
              counterText: '',
              border: none,
              enabledBorder: none,
              focusedBorder: none,
              disabledBorder: none,
              errorBorder: none,
              focusedErrorBorder: none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 19,
              ),
            ),
            validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                ? null
                : 'Masukkan 6 digit kode.',
          ),
        ],
      ),
    );
  }
}

/// Resend control: a small countdown ring until [cooldown] reaches zero.
class OtpResend extends StatelessWidget {
  const OtpResend({
    required this.cooldown,
    required this.onResend,
    this.total = 60,
    super.key,
  });
  final int cooldown, total;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    if (cooldown <= 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onResend,
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('Kirim ulang kode'),
        ),
      );
    }
    final clock = '${cooldown ~/ 60}:${(cooldown % 60).toString().padLeft(2, '0')}';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              value: cooldown / total,
              strokeWidth: 2.5,
              color: AppColors.navy,
              backgroundColor: AppColors.navySoft,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Kirim ulang dalam $clock',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
