part of '../controls.dart';

/// One option in an [ExpressiveButtonGroup].
class ExpressiveSegment<T> {
  const ExpressiveSegment({
    required this.value,
    required this.label,
    this.subtitle,
    this.monogram,
    this.icon,
    this.shape = ExpressiveShape.cookie9,
    this.accent,
  });
  final T value;
  final String label;
  final String? subtitle;
  final String? monogram;
  final IconData? icon;
  final ExpressiveShape shape;
  final Color? accent;
}

/// Connected M3 Expressive button group:
/// - holding a segment widens it (+24%), squashes it like jelly and rounds its
///   inner corners;
/// - the selected segment widens (+28%), rounds into a bold pill/card, lights
///   up in the active palette's hero colour, and spins + morphs its
///   [ExpressiveShape] badge with a corner check dot;
/// - when `vertical: true` (or 3+ segments with subtitles), each segment
///   stacks a 46px animated shape on top of the label + subtitle.
class ExpressiveButtonGroup<T> extends StatefulWidget {
  const ExpressiveButtonGroup({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height,
    this.vertical = false,
    super.key,
  });
  final List<ExpressiveSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double? height;
  final bool vertical;
  @override
  State<ExpressiveButtonGroup<T>> createState() => _ExpressiveButtonGroupState<T>();
}

class _ExpressiveButtonGroupState<T> extends State<ExpressiveButtonGroup<T>> with TickerProviderStateMixin {
  late List<AnimationController> _press, _select;
  late List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final n = widget.segments.length;
    _keys = [for (var i = 0; i < n; i++) GlobalKey()];
    _press = [for (var i = 0; i < n; i++) AnimationController.unbounded(vsync: this)];
    _select = [
      for (final seg in widget.segments)
        AnimationController.unbounded(vsync: this, value: seg.value == widget.selected ? 1 : 0),
    ];
  }

  void _disposeControllers() {
    for (final c in [..._press, ..._select]) {
      c.dispose();
    }
  }

  @override
  void didUpdateWidget(ExpressiveButtonGroup<T> old) {
    super.didUpdateWidget(old);
    if (old.segments.length != widget.segments.length) {
      _disposeControllers();
      _init();
      return;
    }
    if (old.selected != widget.selected) {
      final still = reducedMotion(context);
      for (var i = 0; i < widget.segments.length; i++) {
        final target = widget.segments[i].value == widget.selected ? 1.0 : 0.0;
        still ? _select[i].value = target : springTo(_select[i], target, AppSprings.bouncy);
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _hold(int i, bool down) {
    if (reducedMotion(context)) return;
    springTo(_press[i], down ? 1 : 0, down ? AppSprings.fastSpatial : AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final pal = context.palette;
    final n = widget.segments.length;
    final isVertical = widget.vertical;
    final hasSub = widget.segments.any((s) => s.subtitle != null);
    final h = widget.height ?? (isVertical ? (hasSub ? 116.0 : 100.0) : (hasSub ? 78.0 : 60.0));
    final outerRadius = isVertical || hasSub ? 26.0 : h / 2;
    return SizedBox(
      height: h,
      child: AnimatedBuilder(
        animation: Listenable.merge([..._press, ..._select]),
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              () {
                final seg = widget.segments[i];
                final isSel = seg.value == widget.selected;
                final s = _select[i].value;
                final p = _press[i].value;
                final t = s.clamp(0.0, 1.0);
                final round = math.max(s, p * .75).clamp(0.0, 1.2);
                final inner = Radius.circular((10 + (outerRadius - 10) * round).clamp(8, outerRadius).toDouble());
                final outer = Radius.circular((outerRadius + 4 * t).clamp(16, 32).toDouble());
                final radius = BorderRadius.horizontal(left: i == 0 ? outer : inner, right: i == n - 1 ? outer : inner);
                // Vivid palette hero colour when selected (never muddy brown).
                final bg = Color.lerp(scheme.surfaceContainerHigh, pal.hero, t)!;
                final fg = Color.lerp(scheme.onSurface, pal.onHero, t)!;
                final subFg = Color.lerp(scheme.onSurfaceVariant, pal.onHero.withValues(alpha: .82), t)!;
                final badgeColor = seg.accent ?? scheme.primary;
                final badgeBg = Color.lerp(badgeColor.withValues(alpha: .16), pal.onHero, t)!;
                final badgeFg = Color.lerp(badgeColor, pal.hero, t)!;
                final borderCol = Color.lerp(
                  scheme.outlineVariant.withValues(alpha: .35),
                  pal.onHero.withValues(alpha: .28),
                  t,
                )!;
                final flex = ((1 + .28 * s + .24 * p).clamp(.7, 2.0) * 1000).round();
                final badgeSize = isVertical ? 46.0 : (hasSub ? 44.0 : 34.0);

                final badge = _SegmentBadge(
                  seg: seg,
                  isSel: isSel,
                  s: s,
                  p: p,
                  t: t,
                  badgeSize: badgeSize,
                  badgeBg: badgeBg,
                  badgeFg: badgeFg,
                  bg: bg,
                );

                return Expanded(
                  key: _keys[i],
                  flex: flex,
                  child: Semantics(
                    button: true,
                    selected: isSel,
                    child: Listener(
                      onPointerDown: (_) => _hold(i, true),
                      onPointerUp: (_) => _hold(i, false),
                      onPointerCancel: (_) => _hold(i, false),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(1 + .045 * p, 1 - .055 * p, 1),
                        child: Material(
                          color: bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: radius,
                            side: BorderSide(color: borderCol, width: 1 + .6 * t),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            customBorder: RoundedRectangleBorder(borderRadius: radius),
                            onTap: () {
                              if (isSel) return;
                              HapticFeedback.selectionClick();
                              final ctx = _keys[i].currentContext;
                              if (ctx != null) {
                                ShapeBurst.show(
                                  context,
                                  origin: ShapeBurst.centerOf(ctx),
                                  count: 16,
                                  colors: [pal.hero, scheme.primary, scheme.tertiary, scheme.secondary],
                                );
                              }
                              widget.onChanged(seg.value);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVertical ? 8 : 12,
                                vertical: isVertical ? 10 : 8,
                              ),
                              child: isVertical
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        badge,
                                        const SizedBox(height: 8),
                                        Text(
                                          seg.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.labelLarge?.copyWith(
                                            color: fg,
                                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                          ),
                                        ),
                                        if (seg.subtitle != null)
                                          Text(
                                            seg.subtitle!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context.text.labelSmall?.copyWith(color: subFg, fontSize: 10),
                                          ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        badge,
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                seg.label,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context.text.titleSmall?.copyWith(
                                                  color: fg,
                                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                                ),
                                              ),
                                              if (seg.subtitle != null)
                                                Text(
                                                  seg.subtitle!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: context.text.labelSmall?.copyWith(color: subFg),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }(),
            ],
          ],
        ),
      ),
    );
  }
}
