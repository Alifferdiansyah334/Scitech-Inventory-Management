part of 'playground.dart';

/// One body in a [BallPit].
class PitBall {
  PitBall({required this.radius, required this.child, this.onTap, this.label});
  final double radius;
  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  Offset _p = Offset.zero, _v = Offset.zero;
  double _angle = 0, _spin = 0;
  double _squash = 0;

  void copyStateFrom(PitBall other) {
    _p = other._p;
    _v = other._v;
    _angle = other._angle;
    _spin = other._spin;
    _squash = other._squash;
  }
}

class _BallPanRecognizer extends PanGestureRecognizer {
  _BallPanRecognizer({required this.canGrab});
  bool Function(Offset globalPosition) canGrab;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (event is PointerDownEvent && !canGrab(event.position)) return false;
    return super.isPointerAllowed(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) =>
      globalDistanceMoved.abs() > 6;
}
