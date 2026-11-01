import 'dart:async';
import 'package:flutter/material.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// Pending request card that follows the finger to the right. Past 40 % of
/// its width (or a fling faster than 800 px/s) it flies out and runs
/// [onApprove]; otherwise it springs back with the bouncy preset. Buttons
/// inside the card keep working.
class SwipeToApprove extends StatefulWidget {
  const SwipeToApprove({
    required this.child,
    required this.onApprove,
    this.enabled = true,
    super.key,
  });
  final Widget child;
  final Future<void> Function() onApprove;
  final bool enabled;

  @override
  State<SwipeToApprove> createState() => _SwipeToApproveState();
}

class _SwipeToApproveState extends State<SwipeToApprove>
    with SingleTickerProviderStateMixin {
  late final AnimationController offset = AnimationController.unbounded(
    vsync: this,
  );
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
      if (still) {
        offset.value = width;
      } else {
        unawaited(
          springTo(offset, width * 1.05, AppSprings.snappy, velocity: velocity),
        );
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
      springTo(offset, 0, AppSprings.bouncy, velocity: velocity);
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
                      decoration: BoxDecoration(
                        color: AppColors.okSoft,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.centerLeft,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.ok),
                          SizedBox(width: 8),
                          Text(
                            'Setujui',
                            style: TextStyle(
                              color: AppColors.ok,
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
              builder: (context, child) => Transform.translate(
                offset: Offset(offset.value, 0),
                child: Transform.rotate(
                  angle: (offset.value / width) * 0.05,
                  child: child,
                ),
              ),
              child: widget.child,
            ),
          ],
        ),
      );
    },
  );
}

/// Hint under a queue of swipeable requests.
class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.east_rounded, size: 18, color: AppColors.muted),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Geser kartu ke kanan untuk menyetujui',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
      ],
    ),
  );
}
