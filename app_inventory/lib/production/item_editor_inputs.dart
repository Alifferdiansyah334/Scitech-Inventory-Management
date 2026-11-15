part of 'item_editor.dart';

/// Borderless input inside a radius-18 well, as in [ExpressiveTextField].
InputDecoration _wellDecoration(BuildContext context, String hint) => InputDecoration(
  hintText: hint,
  hintStyle: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant.withValues(alpha: .55)),
  filled: false,
  isDense: true,
  counterText: '',
  errorMaxLines: 3,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
);

/// Whole units: minus and plus discs around a typed number in a well.
class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.controller, required this.min, required this.enabled, required this.validator});
  final TextEditingController controller;
  final int min;
  final bool enabled;
  final FormFieldValidator<String> validator;

  void _step(int delta) {
    final next = ((int.tryParse(controller.text.trim()) ?? min) + delta).clamp(min, 999999);
    HapticFeedback.selectionClick();
    controller.text = '$next';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final value = int.tryParse(controller.text.trim());
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.filledTonal(
            tooltip: 'Kurangi satu',
            onPressed: enabled && (value ?? min) > min ? () => _step(-1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                maxLength: 6,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validator,
                style: context.text.titleLarge?.copyWith(fontFeatures: tabular),
                decoration: _wellDecoration(context, 'Jumlah'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: 'Tambah satu',
            onPressed: enabled ? () => _step(1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      );
    },
  );
}
