import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/password_policy.dart';
import '../ui/controls.dart';
import '../ui/shapes.dart';
import '../ui/springs.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';
import 'password_strength.dart';

part 'forms/prompt_sheet.dart';

class InputSpec {
  const InputSpec(
    this.key,
    this.label, {
    this.initial = '',
    this.optional = false,
    this.secret = false,
    this.numeric = false,
    this.decimal = false,
    this.min = 1,
    this.max = 2000,
    this.validatePassword = false,
    this.icon,
  });
  final String key, label, initial;
  final bool optional, secret, numeric, decimal;
  final bool validatePassword;
  final int min, max;

  /// Badge icon of the editor card; derived from the field kind when null.
  final IconData? icon;

  /// Long free text (notes, reasons) gets a multi-line well.
  bool get long => !secret && !numeric && !decimal && max >= 500;

  IconData get badge =>
      icon ??
      (validatePassword
          ? Icons.password_rounded
          : secret
          ? Icons.lock_outline_rounded
          : numeric
          ? Icons.numbers_rounded
          : decimal
          ? Icons.payments_outlined
          : long
          ? Icons.notes_rounded
          : Icons.short_text_rounded);
}

/// AgroLens "Simpan artikel": full-width filled button (min 56) with a
/// shaped check badge, then 'Batal' as a text button.
class _EditorActions extends StatelessWidget {
  const _EditorActions({required this.submit, required this.onSubmit, required this.onCancel});
  final String submit;
  final VoidCallback? onSubmit, onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final enabled = onSubmit != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.fromLTRB(14, 10, 22, 10),
          ),
          onPressed: onSubmit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShapeIcon(
                icon: Icons.check_rounded,
                shape: ExpressiveShape.cookie9,
                size: 28,
                fill: enabled ? scheme.onPrimary : AppColors.onDisabled,
                foreground: enabled ? scheme.primary : AppColors.disabled,
                iconScale: .6,
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(submit, textAlign: TextAlign.center)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: onCancel,
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

/// Shaped icon beside the editor title (headlineSmall).
class _EditorHeading extends StatelessWidget {
  const _EditorHeading({required this.icon, required this.shape, required this.title});
  final IconData icon;
  final ExpressiveShape shape;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ShapeIcon(icon: icon, shape: shape, size: 52, fill: AppColors.secondary, foreground: AppColors.onSecondary),
      const SizedBox(width: 14),
      Expanded(
        child: Semantics(header: true, child: Text(title, style: context.text.headlineSmall?.copyWith(height: 1.2))),
      ),
    ],
  );
}

/// Bottom-sheet editor (AgroLens article editor in a sheet): one
/// [ExpressiveTextField] per [InputSpec]. Resolves to the trimmed values
/// (secrets untrimmed) keyed by [InputSpec.key], or null when dismissed.
Future<Map<String, String>?> promptForm(
  BuildContext context,
  String title,
  List<InputSpec> fields, {
  String submit = 'Simpan',
  IconData icon = Icons.edit_note_rounded,
}) => showModalBottomSheet<Map<String, String>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  sheetAnimationStyle: sheetAnimation(context),
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (_) => _PromptSheet(title: title, fields: fields, submit: submit, icon: icon),
);

/// AgroLens delete dialog: shaped icon (48; burst on the error container
/// when [danger], cookie9 on the secondary container otherwise), titleLarge
/// title, bodyMedium message, then 'Batal' and the filled [confirm] action
/// (error colours when [danger]). Danger opens with a medium haptic.
Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  IconData icon = Icons.help_outline_rounded,
  bool danger = false,
  String confirm = 'Lanjutkan',
}) async {
  if (danger) HapticFeedback.mediumImpact();
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          icon: ShapeIcon(
            icon: icon,
            shape: danger ? ExpressiveShape.burst : ExpressiveShape.cookie9,
            size: 48,
            fill: danger ? AppColors.errorContainer : AppColors.secondary,
            foreground: danger ? AppColors.onErrorContainer : AppColors.onSecondary,
          ),
          title: Text(title),
          titleTextStyle: context.text.titleLarge?.copyWith(color: context.colors.onSurface),
          content: Text(message, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(
              style: danger
                  ? FilledButton.styleFrom(
                      backgroundColor: context.colors.error,
                      foregroundColor: context.colors.onError,
                    )
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirm),
            ),
          ],
        ),
      ) ??
      false;
}
