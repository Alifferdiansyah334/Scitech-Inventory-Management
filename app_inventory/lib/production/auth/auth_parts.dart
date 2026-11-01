import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// Small label above a filled input, as in the v4 forms.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({required this.label, required this.child, super.key});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Error or confirmation banner separated by tone.
class AuthMessage extends StatelessWidget {
  const AuthMessage({required this.text, this.error = false, super.key});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final fg = error ? AppColors.bad : AppColors.ok;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: error ? AppColors.badSoft : AppColors.okSoft,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              size: 20,
              color: fg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: TextStyle(color: fg, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Email shown as a navySoft chip on the code and reset steps.
class AuthEmailChip extends StatelessWidget {
  const AuthEmailChip({required this.email, super.key});
  final String email;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const ShapeDecoration(
        color: AppColors.navySoft,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_outline, size: 18, color: AppColors.navy),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// "Remember me" checkbox with a full-width tap target.
class RememberToggle extends StatelessWidget {
  const RememberToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onChanged == null ? null : () => onChanged!(!value),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            visualDensity: VisualDensity.compact,
            value: value,
            onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
          ),
          const SizedBox(width: 4),
          const Flexible(
            child: Text(
              'Ingat saya di perangkat ini',
              style: TextStyle(fontSize: 14, color: AppColors.ink),
            ),
          ),
        ],
      ),
    ),
  );
}

/// White auth step: round back button, big title, subtitle and content,
/// centered in a 440 px column on wide screens.
class AuthScreen extends StatelessWidget {
  const AuthScreen({
    required this.title,
    required this.subtitle,
    required this.children,
    this.onBack,
    this.icon,
    super.key,
  });
  final String title, subtitle;
  final List<Widget> children;
  final VoidCallback? onBack;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (icon != null)
                  Positioned(
                    top: -36,
                    right: -64,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 168,
                        height: 168,
                        decoration: const BoxDecoration(
                          color: AppColors.navySoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: const Alignment(-.15, .1),
                        child: Icon(icon, size: 48, color: AppColors.navy),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PressSpring(
                        enabled: onBack != null,
                        child: IconButton(
                          tooltip: 'Kembali',
                          onPressed: onBack,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.paper,
                            foregroundColor: AppColors.ink,
                            fixedSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: EdgeInsets.only(right: icon == null ? 0 : 72),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...children,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
