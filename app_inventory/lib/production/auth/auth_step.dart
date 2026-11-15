part of 'auth_hero.dart';

/// Stable stage shapes shared by the hero and flow indicators.
const authStageShapes = [
  ExpressiveShape.cookie12,
  ExpressiveShape.flower8,
  ExpressiveShape.sunny8,
  ExpressiveShape.softBurst,
];

/// One screen of an authentication flow.
class AuthStep {
  const AuthStep({
    required this.id,
    required this.stage,
    required this.chip,
    required this.chipIcon,
    required this.title,
    required this.body,
    required this.art,
    required this.children,
    required this.action,
    required this.flow,
    required this.index,
    this.top,
    this.footer,
    this.onBack,
  });

  /// Identity of the step; a new id slides the step in and replays it.
  final String id;

  /// Position in [authStageShapes] (hero shape, slide direction).
  final int stage;

  /// Flow name beside the stage shape, with a compact fraction on multi-step flows.
  final String chip;
  final IconData chipIcon;
  final String title, body;

  /// Interactive illustration; [AuthHero.artSize] is the reference proportion.
  final Widget art;

  /// Form below the hero.
  final List<Widget> children;

  /// Full-width primary button of the bottom bar.
  final Widget action;

  /// Text action on the right of the brand bar.
  final Widget? top;

  /// Quiet link under the primary button; stays in the scrollable form.
  final Widget? footer;

  /// Back action on sub-steps (register, forgot, code, reset).
  final VoidCallback? onBack;

  /// Stage indices of every step in this flow, and the current one.
  final List<int> flow;
  final int index;
}

/// Swaps a keyed child with a spring cross-slide: the new one comes in
/// from [direction] (1 = from the right) while the old one leaves the other
/// way and fades. The old child ignores touches and screen readers.
class AuthSwitch extends StatelessWidget {
  const AuthSwitch({required this.direction, required this.child, super.key});
  final double direction;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: reducedMotion(context) ? Duration.zero : defaultSpatialCurve.duration,
    layoutBuilder: (current, previous) =>
        Stack(alignment: AlignmentDirectional.topStart, children: [...previous, ?current]),
    transitionBuilder: (child, animation) {
      final incoming = child.key == this.child.key;
      // FadeTransition fades on the compositor; Opacity in a per-frame
      // builder would repaint the whole subtree through a save layer.
      return ExcludeFocus(
        excluding: !incoming,
        child: IgnorePointer(
          ignoring: !incoming,
          child: ExcludeSemantics(
            excluding: !incoming,
            child: FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Interval(incoming ? 0 : .5, incoming ? .5 : 1)),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final v = animation.value;
                  final t = incoming ? defaultSpatialCurve.transform(v) : v;
                  return Transform.translate(
                    offset: Offset((1 - t) * 44 * direction * (incoming ? 1 : -1), 0),
                    child: child,
                  );
                },
                child: child,
              ),
            ),
          ),
        ),
      );
    },
    child: child,
  );
}
