part of '../components.dart';

/// White card on the tonal canvas (radius 24). Interactive cards tint and
/// morph while held (descendant [ShapeIcon]s morph with them), then spring
/// back. Passive cards stay still; [selected] fills the secondary container.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.radius = AppRadii.xl,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap, onLongPress;
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null || onLongPress != null;
    final content = Padding(padding: padding, child: child);
    final tap = tactileTap(onTap), longPress = tactileTap(onLongPress);
    Widget surface(double p) {
      final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(math.max(0.0, radius - 10 * p)));
      final base = selected ? AppColors.secondary : (color ?? AppColors.card);
      return Material(
        color: Color.lerp(base, AppColors.secondary, .45 * p.clamp(0, 1)),
        shape: shape,
        animationDuration: Duration.zero,
        clipBehavior: Clip.antiAlias,
        child: interactive
            ? InkWell(onTap: tap, onLongPress: longPress, enableFeedback: false, customBorder: shape, child: content)
            : content,
      );
    }

    if (!interactive) return surface(0);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: PressSpring(
        scale: .97,
        squash: .04,
        child: Builder(
          builder: (context) {
            final press = PressSpring.progressOf(context)!;
            return AnimatedBuilder(animation: press, builder: (_, _) => surface(press.value));
          },
        ),
      ),
    );
  }
}

/// Round 48 dp icon button. [filled] gives it the tonal secondary-container
/// disc used in page headers; unfilled takes the surrounding foreground
/// (e.g. on a hero).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = true,
    this.badge = false,
    super.key,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled, badge;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: filled ? AppColors.secondary : Colors.transparent,
      foregroundColor: filled ? AppColors.onSecondary : AppColors.onHero,
      disabledForegroundColor: AppColors.onDisabled,
      minimumSize: const Size(48, 48),
    ),
    icon: Badge(isLabelVisible: badge, backgroundColor: AppColors.accent, smallSize: 9, child: Icon(icon, size: 24)),
  );
}

/// Status bar icons readable on the current hero colour.
SystemUiOverlayStyle heroOverlayStyle() =>
    AppColors.heroIsDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

/// The one bold focus of a screen: a brand-coloured block with all corners
/// at 32 and an optional large soft shape behind the content (top end).
/// Text and icons inside default to [AppColors.onHero].
class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 32,
    this.backdrop = ExpressiveShape.cookie12,
    this.onTap,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Decorative shape behind the content; null for none.
  final ExpressiveShape? backdrop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        if (backdrop != null)
          PositionedDirectional(
            top: -56,
            end: -48,
            child: ExcludeSemantics(
              // Slowly turning soft shape, as on AgroLens' story cards.
              child: Ambient(
                period: const Duration(seconds: 38),
                builder: (context, t, child) => Transform.rotate(angle: .3 + t * 2 * math.pi, child: child),
                child: SizedBox.square(
                  dimension: 220,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(color: AppColors.heroSoft, shape: ExpressiveShapeBorder(backdrop!)),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: padding,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: AppColors.onHero),
            child: IconTheme.merge(
              data: IconThemeData(color: AppColors.onHero),
              child: child,
            ),
          ),
        ),
      ],
    );
    final tap = tactileTap(onTap);
    Widget surface(double p) {
      final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(math.max(0.0, radius - 12 * p)));
      return Material(
        color: Color.lerp(AppColors.hero, AppColors.onHero, .08 * p.clamp(0, 1)),
        shape: shape,
        animationDuration: Duration.zero,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: tap, enableFeedback: false, customBorder: shape, child: content),
      );
    }

    if (onTap == null) return surface(0);
    return Semantics(
      container: true,
      button: true,
      child: PressSpring(
        scale: .98,
        squash: .04,
        child: TiltOnTouch(
          maxAngle: .03,
          child: Builder(
            builder: (context) {
              final press = PressSpring.progressOf(context)!;
              return AnimatedBuilder(animation: press, builder: (_, _) => surface(press.value));
            },
          ),
        ),
      ),
    );
  }
}
