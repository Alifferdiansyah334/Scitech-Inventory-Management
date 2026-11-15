import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'springs.dart';

/// Custom InkWell actions acknowledge activation, not a canceled drag or scroll.
/// Material buttons get their feedback from [expressiveButtonForeground].
VoidCallback? tactileTap(VoidCallback? action) => action == null
    ? null
    : () {
        HapticFeedback.lightImpact();
        action();
      };

/// Keeps Material's gesture, keyboard, focus and disabled handling intact.
/// The outline morphs in the theme; its contents compress and rebound here.
Widget expressiveButtonForeground(BuildContext context, Set<WidgetState> states, Widget? child) => _ButtonFeedback(
  pressed: states.contains(WidgetState.pressed),
  enabled: !states.contains(WidgetState.disabled),
  child: child ?? const SizedBox.shrink(),
);

class _ButtonFeedback extends StatefulWidget {
  const _ButtonFeedback({required this.pressed, required this.enabled, required this.child});

  final bool pressed, enabled;
  final Widget child;

  @override
  State<_ButtonFeedback> createState() => _ButtonFeedbackState();
}

class _ButtonFeedbackState extends State<_ButtonFeedback> with SingleTickerProviderStateMixin {
  late final _press = AnimationController.unbounded(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      _press.stop();
      _press.value = 0;
    }
  }

  @override
  void didUpdateWidget(_ButtonFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    final down = widget.enabled && widget.pressed;
    final wasDown = oldWidget.enabled && oldWidget.pressed;
    if (down == wasDown) return;
    // A light contact acknowledgement, never a claim that an async action
    // succeeded. Success feedback remains owned by the completed operation.
    if (down) HapticFeedback.lightImpact();
    if (reducedMotion(context) || !widget.enabled) {
      _press.stop();
      _press.value = 0;
    } else {
      springTo(_press, down ? 1 : 0, down ? AppSprings.fastSpatial : AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _press,
    child: widget.child,
    builder: (context, child) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(1 - .025 * _press.value, 1 - .09 * _press.value, 1),
      child: child,
    ),
  );
}
