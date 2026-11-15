import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import 'auth_parts.dart';

part 'auth_step.dart';
part 'auth_hero_chip.dart';
part 'auth_confetti.dart';

/// Festive brand hero (Material 3 Expressive): a full brand-colour block with
/// asymmetric organic corners, a stage shape that morphs between steps,
/// drifting confetti shapes, the flow chip, a word-by-word title, step dots
/// and the step's interactive scene. The whole card tilts under the finger.
class AuthHero extends StatefulWidget {
  const AuthHero({
    required this.step,
    required this.direction,
    this.large = false,
    this.topBar,
    this.minHeight,
    super.key,
  });
  final AuthStep step;
  final double direction;
  final bool large;

  /// Optional header row above the hero, on the surrounding surface.
  final Widget? topBar;

  /// Height the page can spare for the hero. When it is generous the hero
  /// stands tall with the scene as its centrepiece instead of leaving an
  /// empty canvas under the form; otherwise the hero keeps its natural size.
  final double? minHeight;

  /// Side of the square scene at phone scale.
  static const artSize = Size(140, 140);

  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero> with SingleTickerProviderStateMixin {
  late final _morph = AnimationController.unbounded(vsync: this, value: 1);
  late int _from = widget.step.stage, _to = widget.step.stage;

  @override
  void didUpdateWidget(AuthHero old) {
    super.didUpdateWidget(old);
    final stage = widget.step.stage;
    if (stage == _to) return;
    _from = _to;
    _to = stage;
    if (reducedMotion(context)) {
      _morph.value = 1;
    } else {
      _morph.value = 0;
      springTo(_morph, 1, AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  /// The big stage shape behind the scene: morphs to the new step's shape on
  /// a bouncy spring and turns slowly.
  Widget _backdrop(double size, Color color, {double spin = 1}) => IgnorePointer(
    child: Ambient(
      period: const Duration(seconds: 40),
      builder: (context, t, _) => AnimatedBuilder(
        animation: _morph,
        builder: (context, _) {
          final m = _morph.value;
          return SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: color,
                shape: ExpressiveShapeBorder(
                  authStageShapes[_from],
                  morphTo: authStageShapes[_to],
                  morph: m,
                  rotation: spin * (t * 2 * math.pi + (_from + (_to - _from) * m) * .9),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _copy() {
    final step = widget.step;
    final on = context.palette.onHero;
    return Column(
      key: ValueKey('copy-${step.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chip(),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: WordReveal(
            step.title,
            style: (widget.large ? context.text.headlineLarge : context.text.headlineSmall)!.copyWith(
              fontSize: widget.large ? 36 : 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
              height: 1.08,
              color: on,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(step.body, style: context.text.bodyMedium?.copyWith(height: 1.4, color: on.withValues(alpha: .86))),
      ],
    );
  }

  Widget _art(double side) => SizedBox.square(
    dimension: side,
    child: AuthSwitch(
      direction: widget.direction,
      child: KeyedSubtree(
        key: ValueKey('art-${widget.step.id}'),
        child: PopIn(child: widget.step.art),
      ),
    ),
  );

  Widget? _dots() {
    final step = widget.step;
    if (step.flow.length < 2) return null;
    final pal = context.palette;
    return AuthStepDots(
      shapes: [for (final i in step.flow) authStageShapes[i]],
      index: step.index,
      color: pal.onHero,
      track: pal.onHero.withValues(alpha: .34),
    );
  }

  Widget _content(BoxConstraints box) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final copy = AuthSwitch(direction: widget.direction, child: _copy());
    final dots = _dots();
    final side = widget.large ? 200.0 : AuthHero.artSize.width;
    if (!widget.large && (box.maxWidth < 300 || textScale > 1.3)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          copy,
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [?dots, const Spacer(), _art(math.min(side, box.maxWidth * .5))],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              if (dots != null) Padding(padding: const EdgeInsets.only(top: 14), child: dots),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _art(math.min(side, box.maxWidth * .42)),
      ],
    );
  }

  /// Inner height of the tall layout, or null when the page has no room for
  /// it (keyboard up, long form, large text, wide panes).
  double? _tallHeight() {
    final min = widget.minHeight;
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    if (widget.large || min == null || min < 320 || textScale > 1.3) return null;
    return min - 38;
  }

  /// Tall phone hero: copy on top, the scene large in the middle of the
  /// remaining block, step dots at its foot.
  Widget _tall(BoxConstraints box, double height) {
    final dots = _dots();
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthSwitch(direction: widget.direction, child: _copy()),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, area) {
                final side = math.min(260.0, math.min(area.maxHeight, box.maxWidth * .78));
                return Stack(
                  children: [
                    if (dots != null) Positioned(left: 0, bottom: 0, child: dots),
                    if (side >= 90) Center(child: _art(side)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final still = reducedMotion(context);
    final blob = widget.large ? 340.0 : 230.0;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(60),
      bottomLeft: Radius.circular(widget.large ? 60 : 48),
      bottomRight: const Radius.circular(24),
    );
    final tall = _tallHeight();
    final content = LayoutBuilder(builder: (context, box) => tall != null ? _tall(box, tall) : _content(box));
    final hero = ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: pal.hero,
        child: Stack(
          children: [
            tall != null
                ? Positioned(right: -blob * .2, bottom: -blob * .05, child: _backdrop(blob * 1.25, pal.heroSoft))
                : Positioned(right: -blob * .28, top: -blob * .3, child: _backdrop(blob, pal.heroSoft)),
            Positioned(left: -64, bottom: -78, child: _backdrop(160, pal.onHero.withValues(alpha: .07), spin: -1)),
            const Positioned.fill(child: _Confetti()),
            Padding(
              padding: widget.large ? const EdgeInsets.all(30) : const EdgeInsets.fromLTRB(20, 18, 14, 20),
              child: still
                  ? content
                  : AnimatedSize(
                      duration: defaultSpatialCurve.duration,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: content,
                    ),
            ),
          ],
        ),
      ),
    );
    final card = TiltOnTouch(maxAngle: .03, child: hero);
    if (widget.topBar == null) return card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(bottom: false, child: widget.topBar!),
        const SizedBox(height: 12),
        card,
      ],
    );
  }
}
