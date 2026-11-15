part of '../components.dart';

/// Empty or problem state that says why and offers the one next action.
class StateMessage extends StatelessWidget {
  const StateMessage({
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
    this.action,
    this.secondaryAction,
    super.key,
  });
  final String title, message;
  final IconData icon;
  final Widget? action, secondaryAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(
      children: [
        ShapeIcon(
          icon: icon,
          shape: ExpressiveShape.softBurst,
          size: 120,
          fill: AppColors.highest,
          foreground: AppColors.muted,
          iconScale: .42,
        ),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
        if (secondaryAction != null) ...[const SizedBox(height: 8), secondaryAction!],
      ],
    ),
  );
}

/// Section heading (titleLarge, 600) with an optional trailing action,
/// usually a [TextButton] such as "Lihat semua".
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.trailing, super.key});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        ),
        if (trailing != null) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 220), child: trailing),
      ],
    ),
  );
}

/// Pill action beside a page title (AgroLens "Pindai"/"Kelola"): a shaped
/// badge and a label in a stadium that squashes on a spring while held.
/// [tonal] uses the secondary container instead of the primary colour.
class PillAction extends StatelessWidget {
  const PillAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.shape = ExpressiveShape.cookie12,
    this.tonal = false,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final ExpressiveShape shape;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = enabled ? (tonal ? AppColors.secondary : AppColors.brand) : AppColors.disabled;
    final fg = enabled ? (tonal ? AppColors.onSecondary : AppColors.onBrand) : AppColors.onDisabled;
    final tap = tactileTap(onPressed);
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: 48, maxWidth: math.max(0.0, MediaQuery.sizeOf(context).width - 32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShapeIcon(
              icon: icon,
              shape: shape,
              size: 28,
              fill: enabled ? (tonal ? AppColors.brand : fg) : AppColors.high,
              foreground: enabled ? (tonal ? AppColors.onBrand : bg) : fg,
              iconScale: .56,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: PressSpring(
        enabled: enabled,
        scale: .92,
        squash: .1,
        child: Builder(
          builder: (context) {
            final press = PressSpring.progressOf(context)!;
            return AnimatedBuilder(
              animation: press,
              child: content,
              builder: (_, child) {
                final p = press.value;
                final border = ShapeBorder.lerp(
                  const StadiumBorder(),
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  p.clamp(0, 1).toDouble(),
                )!;
                return Material(
                  color: Color.lerp(bg, fg, .08 * p.clamp(0, 1)),
                  shape: border,
                  animationDuration: Duration.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(onTap: tap, enableFeedback: false, customBorder: border, child: child),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
