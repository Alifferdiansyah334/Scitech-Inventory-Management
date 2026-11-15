part of 'shapes.dart';

/// An icon inside an expressive shape. Defaults to the category's shape and
/// tint; [fill]/[foreground] override for hero placements. Inside a
/// [PressSpring] (tappable rows and cards) the shape turns and rounds toward
/// a circle while held, following the press spring; the icon stays upright.
class ShapeIcon extends StatelessWidget {
  const ShapeIcon({
    required this.icon,
    this.shape = ExpressiveShape.cookie9,
    this.size = 56,
    this.fill,
    this.foreground,
    this.iconScale = .46,
    super.key,
  });

  ShapeIcon.category(String category, {double size = 56, Color? fill, Color? foreground, Key? key})
    : this._fromStyle(categoryStyle(category), size, fill, foreground, key);

  ShapeIcon._fromStyle(
    ({ExpressiveShape shape, CategoryTone tone, IconData icon}) style,
    double size,
    Color? fill,
    Color? foreground,
    Key? key,
  ) : this(
        icon: style.icon,
        shape: style.shape,
        size: size,
        fill: fill ?? AppColors.category(style.tone).$1,
        foreground: foreground ?? AppColors.category(style.tone).$2,
        key: key,
      );

  final IconData icon;
  final ExpressiveShape shape;
  final double size, iconScale;
  final Color? fill, foreground;

  @override
  Widget build(BuildContext context) {
    final press = PressSpring.progressOf(context);
    Widget shaped(double p) => DecoratedBox(
      decoration: ShapeDecoration(
        color: fill ?? AppColors.fixed,
        shape: ExpressiveShapeBorder(shape, morph: p * .85, rotation: p * math.pi / 6),
      ),
      child: Center(
        child: Icon(icon, size: size * iconScale, color: foreground ?? AppColors.onFixed),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: press == null
          ? shaped(0)
          : AnimatedBuilder(animation: press, builder: (context, _) => shaped(press.value)),
    );
  }
}

/// Clips [child] (usually a photo) to an expressive shape. Inside a
/// [PressSpring] the outline turns toward a circle while held.
class ShapeClip extends StatelessWidget {
  const ShapeClip({required this.shape, required this.child, this.rotation = 0, super.key});
  final ExpressiveShape shape;
  final double rotation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final press = PressSpring.progressOf(context);
    Widget clip(double p) => ClipPath(
      clipper: ShapeBorderClipper(
        shape: ExpressiveShapeBorder(shape, morph: p * .7, rotation: rotation + p * math.pi / 8),
      ),
      child: child,
    );
    return press == null ? clip(0) : AnimatedBuilder(animation: press, builder: (context, _) => clip(press.value));
  }
}

/// Material 3 Expressive loading indicator: a shape that keeps morphing
/// through the shape library while it turns. Reduced motion shows one still
/// shape. [contained] puts it on a round container.
class ExpressiveLoadingIndicator extends StatefulWidget {
  const ExpressiveLoadingIndicator({
    this.size = 48,
    this.color,
    this.contained = false,
    this.containerColor,
    this.semanticsLabel = 'Memuat',
    super.key,
  });
  final double size;
  final Color? color, containerColor;
  final bool contained;
  final String semanticsLabel;

  @override
  State<ExpressiveLoadingIndicator> createState() => _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator> with SingleTickerProviderStateMixin {
  static const _sequence = [
    ExpressiveShape.softBurst,
    ExpressiveShape.cookie9,
    ExpressiveShape.pentagon,
    ExpressiveShape.gem,
    ExpressiveShape.sunny8,
    ExpressiveShape.clover4,
    ExpressiveShape.cookie12,
  ];
  static const _step = 650; // ms per morph, as in the M3 Expressive spec
  late final AnimationController clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _step * 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      clock.stop();
    } else if (!clock.isAnimating) {
      clock.repeat();
    }
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? (widget.contained ? AppColors.onFixed : AppColors.brand);
    final inner = widget.contained ? widget.size * .62 : widget.size;
    final indicator = AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final steps = clock.value * _sequence.length;
        final i = steps.floor() % _sequence.length;
        final local = steps - steps.floor();
        final morph = fastSpatialCurve.transform(local.clamp(0, 1).toDouble());
        // Steady turn plus an extra step carried by each morph; the steps add
        // up to one full turn so the loop has no seam.
        final turn = clock.value * 2 * math.pi + (i + morph) * 2 * math.pi / _sequence.length;
        return SizedBox.square(
          dimension: inner,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: color,
              shape: ExpressiveShapeBorder(
                _sequence[i],
                morphTo: _sequence[(i + 1) % _sequence.length],
                morph: morph,
                rotation: turn,
              ),
            ),
          ),
        );
      },
    );
    return Semantics(
      label: widget.semanticsLabel,
      child: SizedBox.square(
        dimension: widget.size,
        child: widget.contained
            ? DecoratedBox(
                decoration: BoxDecoration(color: widget.containerColor ?? AppColors.fixed, shape: BoxShape.circle),
                child: Center(child: indicator),
              )
            : Center(child: indicator),
      ),
    );
  }
}

/// A bare expressive shape, for badges ("86 siap") and decoration that marks
/// a real state.
class ShapeBadge extends StatelessWidget {
  const ShapeBadge({required this.child, this.shape = ExpressiveShape.sunny8, this.size = 80, this.color, super.key});
  final Widget child;
  final ExpressiveShape shape;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: ShapeDecoration(color: color ?? AppColors.brand, shape: ExpressiveShapeBorder(shape)),
      child: Center(child: child),
    ),
  );
}

/// Stable shape of each colour scheme: its swatch in "Tema & tampilan".
extension SchemeShape on SchemeKey {
  ExpressiveShape get shape => switch (this) {
    SchemeKey.navy => ExpressiveShape.cookie12,
    SchemeKey.cobalt => ExpressiveShape.clover4,
    SchemeKey.emerald => ExpressiveShape.flower8,
    SchemeKey.coral => ExpressiveShape.cookie9,
    SchemeKey.amber => ExpressiveShape.sunny8,
    SchemeKey.violet => ExpressiveShape.gem,
    SchemeKey.magenta => ExpressiveShape.burst,
  };
}
