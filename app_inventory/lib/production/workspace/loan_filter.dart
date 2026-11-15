import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/components.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// One filter card: key passed back, label, how many loans it shows and
/// the status tone it lights up in (null: 'Semua', the primary colour).
typedef LoanFilterOption = ({String key, String label, int count, Tone? tone});

/// Connected row of tall count cards (AgroLens history filter): number,
/// shaped badge and label on each. Held cards widen and squash; the
/// selected one widens, rounds into a pill and takes its status colour on
/// a bouncy spring, with a burst of shapes.
class LoanCountFilter extends StatefulWidget {
  const LoanCountFilter({required this.options, required this.selected, required this.onChanged, super.key});
  final List<LoanFilterOption> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  State<LoanCountFilter> createState() => _LoanCountFilterState();
}

class _LoanCountFilterState extends State<LoanCountFilter> with TickerProviderStateMixin {
  final _press = <String, AnimationController>{};
  final _select = <String, AnimationController>{};
  final _keys = <String, GlobalKey>{};

  AnimationController _controller(Map<String, AnimationController> map, String key, double value) =>
      map[key] ??= AnimationController.unbounded(vsync: this, value: value);

  @override
  void didUpdateWidget(LoanCountFilter old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    final still = reducedMotion(context);
    for (final o in widget.options) {
      final c = _controller(_select, o.key, 0);
      final target = o.key == widget.selected ? 1.0 : 0.0;
      still ? c.value = target : springTo(c, target, AppSprings.bouncy);
    }
  }

  @override
  void dispose() {
    for (final c in [..._press.values, ..._select.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hold(String key, bool down) {
    if (reducedMotion(context)) return;
    springTo(_controller(_press, key, 0), down ? 1 : 0, down ? AppSprings.fastSpatial : AppSprings.bouncy);
  }

  /// Selected colours, badge shape and icon of an option.
  ({Color bg, Color fg, ExpressiveShape shape, IconData icon}) _style(Tone? tone) {
    if (tone == null) {
      return (
        bg: AppColors.brand,
        fg: AppColors.onBrand,
        shape: ExpressiveShape.cookie9,
        icon: Icons.grid_view_rounded,
      );
    }
    final colors = toneColors(tone);
    return (bg: colors.bg, fg: colors.fg, shape: toneShape(tone), icon: toneIcon(tone) ?? Icons.remove_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final presses = [for (final o in options) _controller(_press, o.key, 0)];
    final selects = [for (final o in options) _controller(_select, o.key, o.key == widget.selected ? 1 : 0)];
    final text = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    // 92 tall as in AgroLens, taller when the text is enlarged.
    final height = math.max(92.0, scaler.scale(24) * 1.05 + scaler.scale(12) * 1.4 + 32);
    return LayoutBuilder(
      builder: (context, box) {
        // Labels need ~108 px (more with enlarged text); when the cards would
        // be narrower the row scrolls sideways instead of clipping labels.
        final unit = 108 * (scaler.scale(14) / 14);
        final scroll = (box.maxWidth - 5 * (options.length - 1)) / options.length < unit;
        final row = AnimatedBuilder(
          animation: Listenable.merge([...presses, ...selects]),
          builder: (context, _) => Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                _card(context, text, i, presses[i].value, selects[i].value, scroll ? unit : null),
              ],
            ],
          ),
        );
        return SizedBox(
          height: height,
          child: scroll
              ? SingleChildScrollView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, child: row)
              : row,
        );
      },
    );
  }

  /// [unit] set: fixed card widths (scrolling row) scaled by the same flex.
  Widget _card(BuildContext context, TextTheme text, int i, double p, double s, double? unit) {
    final o = widget.options[i];
    final style = _style(o.tone);
    final selected = o.key == widget.selected;
    final t = s.clamp(0.0, 1.0);
    final round = math.max(s, p * .7).clamp(0.0, 1.2);
    final outerStart = i == 0 ? 28.0 : 10.0;
    final outerEnd = i == widget.options.length - 1 ? 28.0 : 10.0;
    Radius r(double base) => Radius.circular((base + (28 - base) * round).clamp(8.0, 32.0));
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(left: r(outerStart), right: r(outerEnd)),
    );
    final bg = Color.lerp(AppColors.low, style.bg, t)!;
    final fg = Color.lerp(AppColors.ink, style.fg, t)!;
    final badge = Color.lerp(AppColors.highest, style.fg.withValues(alpha: .18), t)!;
    final flex = ((1 + .42 * s + .22 * p).clamp(.7, 1.95) * 1000).round();
    final key = _keys[o.key] ??= GlobalKey();
    Widget sized(Widget child) => unit == null
        ? Expanded(key: key, flex: flex, child: child)
        : SizedBox(key: key, width: unit * flex / 1000, child: child);
    return sized(
      Semantics(
        button: true,
        selected: selected,
        label: '${o.label}, ${o.count} pinjaman',
        excludeSemantics: true,
        child: Listener(
          onPointerDown: (_) => _hold(o.key, true),
          onPointerUp: (_) => _hold(o.key, false),
          onPointerCancel: (_) => _hold(o.key, false),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1 + .04 * p, 1 - .06 * p, 1),
            child: Material(
              color: bg,
              shape: border,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: border,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final ctx = key.currentContext;
                  if (ctx != null && !selected && !reducedMotion(context)) {
                    ShapeBurst.show(
                      context,
                      origin: ShapeBurst.centerOf(ctx),
                      count: 14,
                      colors: [style.bg, style.fg, AppColors.primary, AppColors.secondary],
                    );
                  }
                  widget.onChanged(o.key);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: CountUp(
                                o.count,
                                style: text.headlineSmall?.copyWith(color: fg, height: 1.05, fontFeatures: tabular),
                              ),
                            ),
                          ),
                          SizedBox.square(
                            dimension: 26,
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: badge,
                                shape: ExpressiveShapeBorder(
                                  style.shape,
                                  morph: (p * .6 + s * .25).clamp(0.0, 1.0),
                                  rotation: (s * .85 + p * .4) * math.pi / 4,
                                ),
                              ),
                              child: Center(child: Icon(style.icon, size: 14, color: fg)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        o.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: text.labelMedium?.copyWith(
                          color: fg,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
  }
}
