import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Supplements missing legacy Android IME metrics, without estimating a height
/// from focus or changing platforms whose Flutter metrics already work.
class AndroidKeyboardInsets extends StatefulWidget {
  const AndroidKeyboardInsets({required this.child, this.insets, super.key});

  final Widget child;

  /// Physical-pixel IME measurements; Android supplies these when omitted.
  final Stream<num>? insets;

  @override
  State<AndroidKeyboardInsets> createState() => _AndroidKeyboardInsetsState();
}

class _AndroidKeyboardInsetsState extends State<AndroidKeyboardInsets> {
  double _bottom = 0;

  void _revealCaret() {
    final focus = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bottom <= 0 || focus != FocusManager.instance.primaryFocus) return;
      final editable = focus?.context?.findAncestorStateOfType<EditableTextState>();
      if (editable == null || !editable.widget.controller.selection.isValid) return;
      final render = editable.renderEditable;
      render.showOnScreen(
        rect: editable.widget.scrollPadding.inflateRect(
          render.getLocalRectForCaret(editable.widget.controller.selection.extent),
        ),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    });
  }
  late final Stream<num>? _insets = widget.insets ??
      (!kIsWeb && Platform.isAndroid
          ? const EventChannel('sims/keyboard_insets').receiveBroadcastStream().cast<num>()
          : null);

  @override
  Widget build(BuildContext context) {
    if (_insets == null) return widget.child;
    return StreamBuilder<num>(
      stream: _insets,
      initialData: 0,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          Error.throwWithStackTrace(snapshot.error!, snapshot.stackTrace ?? StackTrace.current);
        }
        final media = MediaQuery.of(context);
        final measured = (snapshot.data ?? 0) / media.devicePixelRatio;
        final supplement = media.viewInsets.bottom == 0 && measured > 0;
        final bottom = supplement ? measured : 0.0;
        if (bottom > _bottom) _revealCaret();
        _bottom = bottom;
        return MediaQuery(
          data: supplement
              ? media.copyWith(
                  viewInsets: media.viewInsets.copyWith(bottom: measured),
                  padding: media.padding.copyWith(
                    bottom: (media.viewPadding.bottom - measured).clamp(0.0, double.infinity),
                  ),
                )
              : media,
          child: widget.child,
        );
      },
    );
  }
}
