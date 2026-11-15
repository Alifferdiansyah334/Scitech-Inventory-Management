import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'springs.dart';

/// Things that move on their own. Every widget here stands still when the
/// system asks for reduced motion, and pauses with its [TickerMode] (hidden
/// tabs, routes covered by another screen).

/// Rebuilds [builder] every frame with a looping `t` in 0..1.
class Ambient extends StatefulWidget {
  const Ambient({required this.builder, this.period = const Duration(seconds: 4), this.child, super.key});
  final Duration period;
  final Widget? child;
  final Widget Function(BuildContext context, double t, Widget? child) builder;

  @override
  State<Ambient> createState() => _AmbientState();
}

class _AmbientState extends State<Ambient> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// The looping subtree repaints every frame; its own layer keeps the rest
  /// of the screen from repainting with it (cheap on low-end devices).
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, child) => widget.builder(context, _c.value, child),
      child: widget.child,
    ),
  );
}

/// Floats up and down (and optionally sways by [turn] radians) forever.
class Bob extends StatelessWidget {
  const Bob({
    required this.child,
    this.distance = 5,
    this.turn = 0,
    this.phase = 0,
    this.period = const Duration(seconds: 4),
    this.alignment = Alignment.center,
    super.key,
  });
  final Widget child;
  final double distance, turn, phase;
  final Duration period;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Ambient(
    period: period,
    child: child,
    builder: (context, t, child) {
      final a = 2 * math.pi * (t + phase);
      return Transform.translate(
        offset: Offset(0, math.sin(a) * distance),
        child: turn == 0 ? child : Transform.rotate(angle: math.cos(a) * turn, alignment: alignment, child: child),
      );
    },
  );
}

/// A dot with a ring that keeps expanding and fading: "found something here".
class PulseRing extends StatelessWidget {
  const PulseRing({required this.color, this.size = 22, this.phase = 0, super.key});
  final Color color;
  final double size, phase;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Ambient(
      period: const Duration(milliseconds: 2000),
      builder: (context, t, _) => CustomPaint(painter: _PulsePainter((t + phase) % 1, color)),
    ),
  );
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.u, this.color);
  final double u;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final max = size.shortestSide / 2;
    canvas
      ..drawCircle(
        c,
        max * (.3 + .7 * u),
        Paint()
          ..color = color.withValues(alpha: (1 - u) * .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawCircle(c, max * .26, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.u != u || old.color != color;
}

/// Text whose words spring up one after another each time [play] turns true.
class WordReveal extends StatefulWidget {
  const WordReveal(this.text, {required this.style, this.play = true, super.key});
  final String text;
  final TextStyle? style;
  final bool play;

  @override
  State<WordReveal> createState() => _WordRevealState();
}

class _WordRevealState extends State<WordReveal> with SingleTickerProviderStateMixin {
  static const _stagger = 70, _span = 520; // ms
  late final _c = AnimationController(vsync: this);
  bool _first = true;

  int get _total => _span + _stagger * (widget.text.split(' ').length - 1);

  void _play() {
    _c
      ..duration = Duration(milliseconds: _total)
      ..forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_first) return;
    _first = false;
    if (reducedMotion(context)) {
      _c.value = 1;
    } else if (widget.play) {
      _play();
    }
  }

  @override
  void didUpdateWidget(WordReveal old) {
    super.didUpdateWidget(old);
    if (reducedMotion(context)) {
      _c.value = 1;
    } else if (widget.play && (!old.play || old.text != widget.text)) {
      _play();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.text.split(' ');
    final total = _total;
    final size = widget.style?.fontSize ?? 16;
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Wrap(
          spacing: size * .26,
          children: [
            for (final (i, word) in words.indexed)
              () {
                final start = i * _stagger / total;
                final local = ((_c.value - start) / (_span / total)).clamp(0.0, 1.0);
                final e = defaultSpatialCurve.transform(local);
                return Opacity(
                  opacity: (local * 2.5).clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, (1 - e) * size * .9),
                    child: Transform.rotate(
                      angle: (1 - e) * .12,
                      alignment: Alignment.bottomLeft,
                      child: Text(word, style: widget.style),
                    ),
                  ),
                );
              }(),
          ],
        ),
      ),
    );
  }
}

/// A number that counts up (or down) to [value] whenever it changes.
class CountUp extends StatelessWidget {
  const CountUp(this.value, {this.style, super.key});
  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => Text('${v.round()}', style: style),
  );
}
