part of 'physics.dart';

/// A one-shot burst of little expressive shapes thrown up from a point,
/// falling under gravity with air drag, spinning and fading out. Celebrates
/// a submitted request or a picked colour scheme.
abstract final class ShapeBurst {
  static void show(BuildContext context, {required Offset origin, required List<Color> colors, int count = 24}) {
    if (reducedMotion(context)) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _Burst(origin: origin, colors: colors, count: count, onDone: () => entry.remove()),
      ),
    );
    overlay.insert(entry);
  }

  /// Centre of [context]'s render box in global coordinates.
  static Offset centerOf(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

class _Particle {
  _Particle(this.position, this.velocity, this.spin, this.path, this.color);
  Offset position, velocity;
  double angle = 0;
  final double spin;
  final Path path;
  final Color color;
}

class _Burst extends StatefulWidget {
  const _Burst({required this.origin, required this.colors, required this.count, required this.onDone});
  final Offset origin;
  final List<Color> colors;
  final int count;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  static const _life = 1.3; // seconds
  static const _gravity = 1900.0; // px/s²
  static const _shapes = [
    ExpressiveShape.cookie9,
    ExpressiveShape.sunny8,
    ExpressiveShape.flower8,
    ExpressiveShape.clover4,
    ExpressiveShape.gem,
    ExpressiveShape.softBurst,
  ];

  late final List<_Particle> _particles;
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = [
      for (var i = 0; i < widget.count; i++)
        () {
          // Thrown upward in a wide cone.
          final a = -math.pi / 2 + (rnd.nextDouble() - .5) * 2.2;
          final speed = 520 + rnd.nextDouble() * 680;
          final size = 12 + rnd.nextDouble() * 14;
          return _Particle(
            widget.origin,
            Offset(math.cos(a), math.sin(a)) * speed,
            (rnd.nextDouble() - .5) * 14,
            expressiveShapePath(
              _shapes[i % _shapes.length],
              Rect.fromCenter(center: Offset.zero, width: size, height: size),
            ),
            widget.colors[i % widget.colors.length],
          );
        }(),
    ];
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0, 1 / 30).toDouble();
    _last = elapsed;
    _t = elapsed.inMicroseconds / 1e6;
    final drag = math.pow(.25, dt).toDouble();
    for (final p in _particles) {
      p.velocity = Offset(p.velocity.dx * drag, p.velocity.dy * drag + _gravity * dt);
      p.position += p.velocity * dt;
      p.angle += p.spin * dt;
    }
    if (_t >= _life) {
      _ticker.stop();
      widget.onDone();
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _BurstPainter(_particles, (1 - (_t - _life * .6) / (_life * .4)).clamp(0, 1)),
  );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.particles, this.opacity);
  final List<_Particle> particles;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.color.a * opacity);
      canvas
        ..save()
        ..translate(p.position.dx, p.position.dy)
        ..rotate(p.angle)
        ..drawPath(p.path, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => true;
}

/// Where the last pointer went down, in global coordinates. [TapOrigin.track]
/// sits at the app root; celebrations burst from the button that was tapped.
abstract final class TapOrigin {
  static Offset? last;

  static Widget track({required Widget child}) =>
      Listener(behavior: HitTestBehavior.translucent, onPointerDown: (e) => last = e.position, child: child);
}

/// Burst of palette shapes from the last tap (or the screen centre) after an
/// operation has succeeded. Never for errors or destructive actions.
void celebrateFrom(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final size = MediaQuery.sizeOf(context);
  ShapeBurst.show(
    context,
    origin: TapOrigin.last ?? size.center(Offset.zero),
    colors: [scheme.primary, scheme.secondaryContainer, scheme.tertiary, scheme.primaryContainer],
  );
}
