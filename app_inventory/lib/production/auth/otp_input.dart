import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/progress.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';

part 'otp_resend.dart';

/// Six connected cells share one real input for selection, paste, autofill
/// and accessibility. Filled cells indicate entry, never verification.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({required this.controller, required this.enabled, this.onSubmitted, super.key});
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onSubmitted;

  static const length = 6;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final focus = FocusNode();
  final fieldKey = GlobalKey<FormFieldState<String>>();

  late Listenable changes;

  @override
  void initState() {
    super.initState();
    changes = Listenable.merge([widget.controller, focus]);
  }

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      changes = Listenable.merge([widget.controller, focus]);
    }
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  void feedback() {
    if (widget.enabled && !reducedMotion(context)) HapticFeedback.selectionClick();
  }

  Widget cell(int i, String text, int active, bool error, double height) {
    final scheme = context.colors;
    final filled = i < text.length;
    final selection = widget.controller.selection;
    final selected =
        focus.hasFocus &&
        widget.enabled &&
        selection.isValid &&
        !selection.isCollapsed &&
        i >= selection.start &&
        i < selection.end;
    final focused = i == active;
    final innerRadius = focused || selected
        ? 18.0
        : filled
        ? 14.0
        : 8.0;
    final outerRadius = filled ? 22.0 : 26.0;
    final fill = !widget.enabled
        ? scheme.surfaceContainerHigh
        : error
        ? scheme.errorContainer
        : selected
        ? scheme.secondaryContainer
        : filled
        ? scheme.primaryContainer
        : scheme.surfaceContainerLowest;
    final outline = error
        ? scheme.error
        : focused || selected
        ? scheme.primary
        : scheme.outlineVariant;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedContainer(
          duration: reducedMotion(context) ? Duration.zero : fastSpatialCurve.duration,
          curve: fastSpatialCurve,
          height: height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(i == 0 ? outerRadius : innerRadius),
              right: Radius.circular(i == OtpCodeField.length - 1 ? outerRadius : innerRadius),
            ),
            border: Border.all(
              color: widget.enabled ? outline : scheme.outlineVariant.withValues(alpha: .5),
              width: focused || selected ? 2.5 : 1,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 3,
                width: focused ? 12 : 0,
                decoration: BoxDecoration(color: outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Form validation also rebuilds the visible, unconstrained error below.
    Form.maybeOf(context);
    final error = fieldKey.currentState?.errorText;
    final scheme = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, box) {
          final stride = math.max(1.0, (box.maxWidth - 8) / OtpCodeField.length);
          // Fit large digits inside six cells, while labels retain full scaling.
          final fontSize = math.min(MediaQuery.textScalerOf(context).scale(24), stride * .9);
          final height = math.max(64.0, fontSize * 1.5 + 24);
          final digitStyle = context.text.headlineSmall!.copyWith(
            fontSize: fontSize,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: !widget.enabled
                ? scheme.onSurface.withValues(alpha: .38)
                : error != null
                ? scheme.onErrorContainer
                : scheme.onPrimaryContainer,
          );
          final digitWidth = TextPainter.computeWidth(
            text: TextSpan(text: '0', style: digitStyle),
            textDirection: TextDirection.ltr,
          );
          return ListenableBuilder(
            listenable: changes,
            builder: (context, _) {
              final text = widget.controller.text;
              final count = math.min(text.length, OtpCodeField.length);
              final selection = widget.controller.selection;
              final active = focus.hasFocus && widget.enabled
                  ? (selection.isValid ? selection.extentOffset : count).clamp(0, OtpCodeField.length - 1)
                  : -1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text('Kode verifikasi', style: context.text.titleSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count/6 digit terisi',
                          style: context.text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PressSpring(
                    enabled: widget.enabled,
                    scale: .985,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Stack(
                          children: [
                            ExcludeSemantics(
                              child: Row(
                                textDirection: TextDirection.ltr,
                                children: [
                                  for (var i = 0; i < OtpCodeField.length; i++)
                                    cell(i, text, active, error != null, height),
                                ],
                              ),
                            ),
                            Positioned.fill(
                              // Glyph advance matches each cell, so native tap,
                              // drag, keyboard and selection handles stay usable.
                              child: MediaQuery(
                                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                                child: Semantics(
                                  label: 'Kode OTP 6 digit',
                                  child: TextFormField(
                                    key: fieldKey,
                                    controller: widget.controller,
                                    focusNode: focus,
                                    enabled: widget.enabled,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    textDirection: TextDirection.ltr,
                                    textAlignVertical: TextAlignVertical.center,
                                    autofillHints: const [AutofillHints.oneTimeCode],
                                    onTap: feedback,
                                    onTapAlwaysCalled: true,
                                    onChanged: (_) => feedback(),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    maxLength: OtpCodeField.length,
                                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    enableIMEPersonalizedLearning: false,
                                    showCursor: false,
                                    cursorWidth: 0,
                                    scrollPadding: const EdgeInsets.all(32),
                                    onFieldSubmitted: (_) {
                                      if (widget.enabled) widget.onSubmitted?.call();
                                    },
                                    style: digitStyle.copyWith(letterSpacing: stride - digitWidth),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      filled: false,
                                      isDense: true,
                                      counterText: '',
                                      // Glyph advance already matches each cell horizontally;
                                      // pad vertically so digits sit in the cell centre.
                                      contentPadding: EdgeInsets.symmetric(vertical: (height - fontSize * 1.2) / 2),
                                      errorStyle: const TextStyle(fontSize: 0, height: 0),
                                    ),
                                    validator: (value) =>
                                        RegExp(r'^\d{6}$').hasMatch(value ?? '') ? null : 'Masukkan 6 digit kode.',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (error != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(error, style: context.text.bodySmall?.copyWith(color: scheme.error)),
                    )
                  else
                    Text(
                      count == OtpCodeField.length
                          ? 'Kode lengkap. Tekan Verifikasi untuk memeriksa kode.'
                          : count == 0
                          ? 'Tempel kode atau masukkan satu per satu.'
                          : 'Masukkan ${OtpCodeField.length - count} digit lagi.',
                      style: context.text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
