import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/brand.dart';
import '../ui/brand_mark.dart';
import '../ui/shapes.dart';
import '../ui/springs.dart';
import '../ui/palette.dart';
import '../ui/theme.dart';

/// Equipment categories that gather around the mark, as on the sign-in hero.
const _orbit = ['Kamera', 'Drone', 'Audio', 'Proyektor', 'Perkakas'];

/// Launch moment in Material 3 Expressive: on the brand colour a white plate
/// springs in and morphs circle → cookie, the SIMS mark pops onto it, the
/// equipment categories fly in from the edges and settle into an orbit, and
/// the name lands letter by letter with the tagline under it.
///
/// One linear controller drives the whole timeline; each element reads its
/// own window through spring curves, so the splash costs one ticker however
/// many shapes move. [onDone] fires when the timeline ends (at once with
/// reduced motion); [busy] adds a loading shape while the stored session is
/// still being checked.
class BrandSplash extends StatefulWidget {
  const BrandSplash({required this.busy, required this.onDone, super.key});
  final bool busy;
  final VoidCallback onDone;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> with SingleTickerProviderStateMixin {
  late final _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  static final _bouncy = SpringCurve(AppSprings.bouncy);
  static final _spatial = SpringCurve(AppSprings.defaultSpatial);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t.isAnimating || _t.value != 0) return;
    if (reducedMotion(context)) {
      _t.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
    _t.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  /// Progress of the window [start]..[end] of the timeline through [curve]
  /// (spring curves overshoot past 1 before settling).
  double _phase(double start, double end, Curve curve) {
    final local = ((_t.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(local);
  }

  Widget _blob(double size, Color color, double spin) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
        shape: ExpressiveShapeBorder(
          ExpressiveShape.cookie12,
          morphTo: ExpressiveShape.flower8,
          morph: _t.value,
          rotation: spin * _t.value * math.pi / 2,
        ),
      ),
    ),
  );

  Widget _stage(BuildContext context) {
    final pal = context.palette;
    final plate = _phase(0, .5, _bouncy);
    final mark = _phase(.18, .62, _bouncy);
    const orbitRadius = 128.0, start = 320.0;
    return SizedBox.square(
      dimension: 320,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < _orbit.length; i++)
            () {
              final p = _phase(.2 + i * .07, .7 + i * .06, _spatial);
              final angle = -math.pi / 2 + i * 2 * math.pi / _orbit.length + _t.value * .6;
              final r = start + (orbitRadius - start) * p;
              return Transform.translate(
                offset: Offset(math.cos(angle), math.sin(angle)) * r,
                child: Transform.rotate(
                  angle: (1 - p) * 1.4,
                  child: Opacity(opacity: p.clamp(0.0, 1.0), child: ShapeIcon.category(_orbit[i], size: 52)),
                ),
              );
            }(),
          Transform.scale(
            scale: .35 + .65 * plate,
            child: SizedBox.square(
              dimension: 176,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: pal.onHero,
                  shape: ExpressiveShapeBorder(
                    ExpressiveShape.circle,
                    morphTo: ExpressiveShape.cookie12,
                    morph: plate,
                    rotation: (1 - plate) * math.pi / 3,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: mark.clamp(0.0, 1.0),
                    child: Transform.scale(scale: .6 + .4 * mark, child: const BrandMark(size: 96)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _name(BuildContext context) {
    final on = context.palette.onHero;
    final style = context.text.displaySmall?.copyWith(
      color: on,
      fontWeight: FontWeight.w800,
      letterSpacing: 4,
      height: 1,
    );
    final tagline = _phase(.72, 1, Curves.easeOutCubic);
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, letter) in appName.split('').indexed)
                () {
                  final p = _phase(.48 + i * .06, .82 + i * .05, _bouncy);
                  return Opacity(
                    opacity: p.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - p) * 28),
                      child: Transform.scale(
                        scale: .6 + .4 * p,
                        child: Text(letter, style: style),
                      ),
                    ),
                  );
                }(),
            ],
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: tagline,
            child: Transform.translate(
              offset: Offset(0, (1 - tagline) * 10),
              child: Text(
                appTagline,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: on.withValues(alpha: .82)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final size = MediaQuery.sizeOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.heroIsDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: pal.hero,
        body: Semantics(
          label: '$appName, $appTagline',
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -size.width * .35,
                  top: -size.width * .3,
                  child: _blob(size.width * .95, pal.heroSoft, 1),
                ),
                Positioned(
                  left: -size.width * .4,
                  bottom: -size.width * .35,
                  child: _blob(size.width * .8, pal.onHero.withValues(alpha: .06), -1),
                ),
                SafeArea(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [_stage(context), const SizedBox(height: 28), _name(context)],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.busy)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.paddingOf(context).bottom + 56,
                    child: Center(
                      child: ExpressiveLoadingIndicator(size: 44, color: pal.onHero, semanticsLabel: 'Memulihkan sesi'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
