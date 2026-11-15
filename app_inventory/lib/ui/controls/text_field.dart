part of '../controls.dart';

/// Material 3 Expressive text field used by every form in the app (sign in,
/// register, recovery, request, item editor, profile, admin prompts): one
/// tonal field, not a card around a second well.
/// - Press squashes it on the shared [PressSpring]; a tap gives a selection
///   haptic; focus morphs its corners (24 → 16), lights the outline and
///   turns and recolours the leading shape badge on a bouncy spring.
/// - Each typed character pops the badge and throws a shaped letter out of
///   the field; long text shows a word count under it.
///
/// [obscureText] fields never reveal what was typed: the floating shapes show
/// dots instead of letters. Reduced motion keeps the field fully usable and
/// drops only the springs and floating shapes.
class ExpressiveTextField extends StatefulWidget {
  const ExpressiveTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.shape = ExpressiveShape.cookie9,
    this.hint,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.sentences,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.focusNode,
    this.trailing,
    this.onChanged,
    this.onFieldSubmitted,
    this.showWordCount,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ExpressiveShape shape;

  /// Placeholder shown once the label has floated.
  final String? hint;
  final FormFieldValidator<String>? validator;
  final int minLines;
  final int? maxLines;
  final TextCapitalization capitalization;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText, enabled, autofocus;
  final int? maxLength;
  final FocusNode? focusNode;

  /// Widget at the end of the field, e.g. a show-password toggle.
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  /// Word count under the field; defaults to on for multi-line fields.
  final bool? showWordCount;

  @override
  State<ExpressiveTextField> createState() => _ExpressiveTextFieldState();
}

/// Filled-field border whose floating label stays inside the tonal fill (it
/// is not an outline border, so the label never sits on the edge), while
/// still drawing a full rounded stroke for focus and error.
class _TonalFieldBorder extends UnderlineInputBorder {
  const _TonalFieldBorder({super.borderSide = BorderSide.none, required super.borderRadius});

  @override
  _TonalFieldBorder copyWith({BorderSide? borderSide, BorderRadius? borderRadius}) =>
      _TonalFieldBorder(borderSide: borderSide ?? this.borderSide, borderRadius: borderRadius ?? this.borderRadius);

  @override
  _TonalFieldBorder scale(double t) =>
      _TonalFieldBorder(borderSide: borderSide.scale(t), borderRadius: borderRadius * t);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is _TonalFieldBorder
      ? _TonalFieldBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
          borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is _TonalFieldBorder
      ? _TonalFieldBorder(
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
          borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        )
      : super.lerpTo(b, t);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(borderSide.width / 2), borderSide.toPaint());
  }
}
