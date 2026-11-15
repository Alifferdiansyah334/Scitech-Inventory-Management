import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/brand.dart';
import '../../ui/components.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../workspace/chrome.dart';

/// SIMS mark tinted in the brand colour; announced once as the app name.
class AuthLogo extends StatelessWidget {
  const AuthLogo({this.size = 30, this.color, super.key});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: appName,
    image: true,
    child: WhiteLogo(size: size, color: color ?? context.colors.primary),
  );
}

/// Error or confirmation note: a card with a tone shape badge (AgroLens
/// notices), announced as a live region.
class AuthMessage extends StatelessWidget {
  const AuthMessage({required this.text, this.error = false, super.key});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final tone = toneColors(error ? Tone.bad : Tone.ok);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: PopIn(
          key: ValueKey(text),
          child: DecoratedBox(
            decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShapeIcon(
                    icon: error ? Icons.priority_high_rounded : Icons.check_rounded,
                    shape: error ? ExpressiveShape.burst : ExpressiveShape.cookie9,
                    size: 36,
                    fill: tone.fg,
                    foreground: tone.bg,
                    iconScale: .5,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(text, style: context.text.bodyMedium?.copyWith(color: tone.fg)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Ingat perangkat" as the AgroLens featured toggle card: the badge morphs
/// sunny → cookie and the card warms to the secondary container when on.
class RememberToggle extends StatefulWidget {
  const RememberToggle({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<RememberToggle> createState() => _RememberToggleState();
}

class _RememberToggleState extends State<RememberToggle> with SingleTickerProviderStateMixin {
  late final _sel = AnimationController.unbounded(vsync: this, value: widget.value ? 1 : 0);
  final _badgeKey = GlobalKey();

  @override
  void didUpdateWidget(RememberToggle old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final target = widget.value ? 1.0 : 0.0;
      reducedMotion(context) ? _sel.value = target : springTo(_sel, target, AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  void _toggle() {
    final change = widget.onChanged;
    if (change == null) return;
    HapticFeedback.selectionClick();
    final badge = _badgeKey.currentContext;
    if (badge != null && !widget.value) {
      final scheme = context.colors;
      ShapeBurst.show(
        context,
        origin: ShapeBurst.centerOf(badge),
        count: 14,
        colors: [scheme.primary, scheme.tertiary, scheme.secondary, context.palette.hero],
      );
    }
    change(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final enabled = widget.onChanged != null;
    return MergeSemantics(
      child: PressSpring(
        enabled: enabled,
        squash: .07,
        scale: .97,
        child: AnimatedBuilder(
          animation: _sel,
          builder: (context, _) {
            final t = _sel.value.clamp(0.0, 1.0);
            final radius = BorderRadius.circular(22 + 6 * t);
            final fg = Color.lerp(scheme.onSurface, scheme.onSecondaryContainer, t)!;
            return Material(
              color: Color.lerp(scheme.surfaceContainerLow, scheme.secondaryContainer, t),
              shape: RoundedRectangleBorder(borderRadius: radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: RoundedRectangleBorder(borderRadius: radius),
                onTap: enabled ? _toggle : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox.square(
                        key: _badgeKey,
                        dimension: 34,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: Color.lerp(scheme.surfaceContainerHighest, scheme.primary, t),
                            shape: ExpressiveShapeBorder(
                              ExpressiveShape.sunny8,
                              morphTo: ExpressiveShape.cookie12,
                              morph: _sel.value.clamp(0.0, 1.25),
                              rotation: _sel.value * .8,
                            ),
                          ),
                          child: Icon(
                            widget.value ? Icons.verified_user_rounded : Icons.phonelink_lock_outlined,
                            size: 22,
                            color: Color.lerp(scheme.onSurfaceVariant, scheme.onPrimary, t),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ingat perangkat', style: context.text.titleSmall?.copyWith(color: fg)),
                            Text(
                              'Tetap masuk di perangkat ini',
                              style: context.text.bodySmall?.copyWith(color: fg.withValues(alpha: .8)),
                            ),
                          ],
                        ),
                      ),
                      Switch(value: widget.value, onChanged: enabled ? (_) => _toggle() : null),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Step indicator of the AgroLens onboarding: each step is a dot that grows
/// (12 → 24) and morphs into its stage shape, turning by π/3, when current.
/// [color] paints the current dot and [track] the others (primary and
/// outline variant by default; the hero passes its foreground).
class AuthStepDots extends StatelessWidget {
  const AuthStepDots({required this.shapes, required this.index, this.color, this.track, super.key});
  final List<ExpressiveShape> shapes;
  final int index;
  final Color? color, track;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Langkah ${index + 1} dari ${shapes.length}',
    child: ExcludeSemantics(
      child: SizedBox(
        height: 28,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, shape) in shapes.indexed)
              _ShapeDot(
                key: ValueKey(i),
                shape: shape,
                selected: i == index,
                color: color ?? context.colors.primary,
                track: track ?? context.colors.outlineVariant,
              ),
          ],
        ),
      ),
    ),
  );
}

class _ShapeDot extends StatefulWidget {
  const _ShapeDot({required this.shape, required this.selected, required this.color, required this.track, super.key});
  final ExpressiveShape shape;
  final bool selected;
  final Color color, track;

  @override
  State<_ShapeDot> createState() => _ShapeDotState();
}

class _ShapeDotState extends State<_ShapeDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController.unbounded(vsync: this, value: widget.selected ? 1 : 0);

  @override
  void didUpdateWidget(_ShapeDot old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      final target = widget.selected ? 1.0 : 0.0;
      reducedMotion(context) ? _c.value = target : springTo(_c, target, AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final t = _c.value;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: SizedBox.square(
          dimension: 12 + 12 * t.clamp(0.0, 1.3),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Color.lerp(widget.track, widget.color, t.clamp(0.0, 1.0)),
              shape: ExpressiveShapeBorder(
                ExpressiveShape.circle,
                morphTo: widget.shape,
                morph: t,
                rotation: t * math.pi / 3,
              ),
            ),
          ),
        ),
      );
    },
  );
}
