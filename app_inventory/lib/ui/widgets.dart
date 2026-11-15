import 'package:flutter/material.dart';

import 'springs.dart';

/// Fades and springs a child up into place the first time it is on screen:
/// [index] steps after the screen opens, or when it is scrolled into view.
/// Reduced motion shows it immediately.
class Reveal extends StatefulWidget {
  const Reveal({required this.child, this.index = 0, this.offset = 24, super.key});
  final Widget child;
  final int index;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);
  ScrollPosition? _position;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    if (reducedMotion(context)) {
      _started = true;
      _c.value = 1;
      return;
    }
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_started || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final viewHeight = View.of(context).physicalSize.height / View.of(context).devicePixelRatio;
    if (box.localToGlobal(Offset.zero).dy > viewHeight - 24) return;
    _started = true;
    _position?.removeListener(_check);
    Future.delayed(Duration(milliseconds: 40 + widget.index * 55), () {
      if (mounted) springTo(_c, 1, AppSprings.defaultSpatial, velocity: 0);
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Opacity(
      opacity: _c.value.clamp(0, 1).toDouble(),
      child: Transform.translate(offset: Offset(0, widget.offset * (1 - _c.value)), child: child),
    ),
    child: widget.child,
  );
}
