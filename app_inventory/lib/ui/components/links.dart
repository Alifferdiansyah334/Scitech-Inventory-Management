part of '../components.dart';

/// Settings-style group: a large-cornered tonal card with a shaped badge,
/// title and optional current-value pill, then its content.
class GroupCard extends StatelessWidget {
  const GroupCard({
    required this.title,
    required this.icon,
    required this.child,
    this.shape = ExpressiveShape.cookie9,
    this.value,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final String title;
  final IconData icon;
  final ExpressiveShape shape;

  /// Current choice shown as a pill at the end of the header row.
  final String? value;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.low,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xxl)),
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ShapeIcon(
                icon: icon,
                shape: shape,
                size: 40,
                fill: AppColors.secondary,
                foreground: AppColors.onSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
                    transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                    child: Container(
                      key: ValueKey(value),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        value!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(color: AppColors.onSecondary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

/// Connected navigation rows: outer corners 28, inner 8, 4 px apart.
class LinkGroup extends StatelessWidget {
  const LinkGroup({required this.children, super.key});
  final List<LinkTile> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 4),
        _LinkScope(first: i == 0, last: i == children.length - 1, child: children[i]),
      ],
    ],
  );
}

class _LinkScope extends InheritedWidget {
  const _LinkScope({required this.first, required this.last, required super.child});
  final bool first, last;
  @override
  bool updateShouldNotify(_LinkScope old) => first != old.first || last != old.last;
}

/// A row that opens something: shaped badge, title (+ subtitle), trailing
/// shaped arrow that nudges forward while held. Inner corners round off
/// and the row tints toward the secondary container under the finger.
class LinkTile extends StatelessWidget {
  const LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.shape = ExpressiveShape.cookie9,
    this.selected = false,
    this.trailing,
    this.danger = false,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final ExpressiveShape shape;
  final VoidCallback? onTap;
  final bool selected, danger;

  /// Replaces the arrow (e.g. a count pill or a switch).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LinkScope>();
    final first = scope?.first ?? true, last = scope?.last ?? true;
    final tap = tactileTap(onTap);
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      selected: selected,
      child: PressSpring(
        enabled: onTap != null,
        scale: .97,
        squash: .06,
        child: Builder(
          builder: (context) {
            final press = PressSpring.progressOf(context);
            Widget row(double p) {
              final inner = Radius.circular(math.max(0.0, 8 + 12 * p));
              final outer = Radius.circular(math.max(0.0, AppRadii.xxl - 10 * p));
              final radius = BorderRadius.vertical(top: first ? outer : inner, bottom: last ? outer : inner);
              final base = selected ? AppColors.secondary : AppColors.card;
              final fill = danger ? AppColors.errorContainer : AppColors.secondary;
              final fg = danger ? AppColors.onErrorContainer : AppColors.onSecondary;
              return Material(
                color: Color.lerp(base, AppColors.secondary, .45 * p.clamp(0, 1))!,
                shape: RoundedRectangleBorder(borderRadius: radius),
                animationDuration: Duration.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: tap,
                  enableFeedback: false,
                  customBorder: RoundedRectangleBorder(borderRadius: radius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final below = trailing != null && box.maxWidth < 420;
                          final details = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: danger ? AppColors.error : AppColors.ink,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(subtitle!, style: TextStyle(fontSize: 14, color: AppColors.muted)),
                              ],
                            ],
                          );
                          final end =
                              trailing ??
                              Transform.translate(
                                offset: Offset(4 * p, 0),
                                child: ShapeIcon(
                                  icon: Icons.arrow_forward_rounded,
                                  shape: ExpressiveShape.cookie9,
                                  size: 34,
                                  fill: AppColors.high,
                                  foreground: AppColors.ink,
                                ),
                              );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  ShapeIcon(icon: icon, shape: shape, size: 44, fill: fill, foreground: fg),
                                  const SizedBox(width: 14),
                                  Expanded(child: details),
                                  if (!below) ...[const SizedBox(width: 8), end],
                                ],
                              ),
                              if (below) ...[
                                const SizedBox(height: 10),
                                Align(alignment: AlignmentDirectional.centerEnd, child: end),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }

            return press == null ? row(0) : AnimatedBuilder(animation: press, builder: (_, _) => row(press.value));
          },
        ),
      ),
    );
  }
}
