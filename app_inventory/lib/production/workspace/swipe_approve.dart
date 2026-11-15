import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';
import 'chrome.dart';

/// Pending request row that follows the finger to the right. Past 40 % of
/// its width (or a fling faster than 800 px/s) it flies out and runs
/// [onApprove]; otherwise it springs back with the default spatial spring. Taps and
/// buttons inside the row keep working. The row's own rounded (24) clip
/// hides it as it slides out over the approve background.
class SwipeToApprove extends StatefulWidget {
  const SwipeToApprove({required this.child, required this.onApprove, this.enabled = true, super.key});
  final Widget child;
  final Future<void> Function() onApprove;
  final bool enabled;

  @override
  State<SwipeToApprove> createState() => _SwipeToApproveState();
}

class _SwipeToApproveState extends State<SwipeToApprove> with SingleTickerProviderStateMixin {
  late final AnimationController offset = AnimationController.unbounded(vsync: this);
  double width = 1;
  bool approving = false;

  bool get active => widget.enabled && !approving;

  void drag(DragUpdateDetails details) {
    if (!active) return;
    offset.stop();
    final delta = details.primaryDelta ?? 0;
    // Leftward drags only stretch a little: there is no left action.
    offset.value += offset.value + delta < 0 ? delta * 0.3 : delta;
  }

  Future<void> release(DragEndDetails details) async {
    if (!active) return;
    final velocity = details.primaryVelocity ?? 0;
    final still = reducedMotion(context);
    if (offset.value > width * 0.4 || velocity > 800) {
      approving = true;
      HapticFeedback.mediumImpact();
      if (still) {
        offset.value = width;
      } else {
        unawaited(springTo(offset, width * 1.05, AppSprings.fastSpatial, velocity: velocity));
      }
      await widget.onApprove();
      if (!mounted) return;
      approving = false;
      settle(0);
      return;
    }
    settle(velocity);
  }

  void settle(double velocity) {
    if (reducedMotion(context)) {
      offset.value = 0;
    } else {
      springTo(offset, 0, AppSprings.defaultSpatial, velocity: velocity);
    }
  }

  @override
  void dispose() {
    offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      width = constraints.maxWidth;
      return GestureDetector(
        onHorizontalDragUpdate: widget.enabled ? drag : null,
        onHorizontalDragEnd: widget.enabled ? release : null,
        onHorizontalDragCancel: widget.enabled ? () => settle(0) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: offset,
                  builder: (context, _) {
                    final reveal = (offset.value / (width * 0.4)).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: reveal,
                      child: Container(
                        color: AppColors.okContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: reveal * math.pi / 4,
                              child: ShapeIcon(
                                icon: Icons.check_rounded,
                                shape: ExpressiveShape.flower8,
                                size: 36 + 4 * reveal,
                                fill: AppColors.onOkContainer,
                                foreground: AppColors.okContainer,
                                iconScale: .5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Setujui',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.onOkContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              AnimatedBuilder(
                animation: offset,
                builder: (context, child) => Transform.translate(offset: Offset(offset.value, 0), child: child),
                child: widget.child,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Hint under a list with swipeable pending requests. Phones only: wide
/// layouts already show explicit approve and reject buttons.
class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) => chromeWide(context)
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: AppSpace.md),
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
              decoration: BoxDecoration(color: AppColors.low, borderRadius: BorderRadius.circular(AppRadii.full)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShapeIcon(
                    icon: Icons.swipe_right_rounded,
                    shape: ExpressiveShape.flower8,
                    size: 32,
                    fill: AppColors.okContainer,
                    foreground: AppColors.onOkContainer,
                    iconScale: .55,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Geser permintaan ke kanan untuk menyetujui',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
}
