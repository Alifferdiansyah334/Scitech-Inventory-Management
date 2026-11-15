import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models.dart';
import '../../ui/components.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// A slice of the admin queue: what the dashboard filters by, the loans
/// filter key it opens in 'Pinjaman', the empty-state sentence and how its
/// count card looks.
class QueueBucket {
  const QueueBucket(
    this.label,
    this.loansFilter,
    this.empty,
    this.test, {
    required this.tone,
    required this.icon,
    required this.shape,
  });
  final String label, loansFilter, empty;
  final bool Function(Loan loan) test;
  final Tone tone;
  final IconData icon;
  final ExpressiveShape shape;
}

bool _late(Loan l) => l.late || l.status == 'overdue';

final queueBuckets = <QueueBucket>[
  QueueBucket(
    'Menunggu',
    'pending',
    'Tidak ada permintaan yang menunggu persetujuan.',
    (l) => l.status == 'pending',
    tone: Tone.waiting,
    icon: Icons.schedule_rounded,
    shape: ExpressiveShape.sunny8,
  ),
  QueueBucket(
    'Siap diambil',
    'approved',
    'Belum ada pinjaman yang siap diambil.',
    (l) => l.status == 'approved',
    tone: Tone.ok,
    icon: Icons.check_rounded,
    shape: ExpressiveShape.flower8,
  ),
  QueueBucket(
    'Dipinjam',
    'borrowed',
    'Tidak ada barang yang sedang dipinjam.',
    (l) => l.status == 'borrowed' && !_late(l),
    tone: Tone.info,
    icon: Icons.outbox_outlined,
    shape: ExpressiveShape.cookie9,
  ),
  QueueBucket(
    'Terlambat',
    'late',
    'Tidak ada pinjaman yang terlambat.',
    _late,
    tone: Tone.bad,
    icon: Icons.priority_high_rounded,
    shape: ExpressiveShape.burst,
  ),
  QueueBucket(
    'Perlu dicek',
    'returning',
    'Tidak ada pengembalian yang perlu dicek.',
    (l) => const ['returning', 'needs_review'].contains(l.status),
    tone: Tone.waiting,
    icon: Icons.fact_check_outlined,
    shape: ExpressiveShape.softBurst,
  ),
];

/// One count card. A null [tone] ("Semua") selects into the hero colour.
class CountFilter {
  const CountFilter({required this.label, required this.count, required this.icon, required this.shape, this.tone});
  final String label;
  final int count;
  final IconData icon;
  final ExpressiveShape shape;
  final Tone? tone;

  ({Color fg, Color bg}) get colors => tone == null ? (fg: AppColors.onBrand, bg: AppColors.brand) : toneColors(tone!);
}

/// Real counts as filters, after AgroLens' history filter: connected tonal
/// cards, each with its own shaped badge. Held cards widen and squash; the
/// selected card widens, rounds into a pill and takes its status colour on
/// a bouncy spring, with a burst of 14 shapes. When the cards do not fit (phones, enlarged text) the
/// group scrolls sideways.
class CountFilterGroup extends StatefulWidget {
  const CountFilterGroup({required this.filters, required this.selected, required this.onSelect, super.key});
  final List<CountFilter> filters;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  State<CountFilterGroup> createState() => _CountFilterGroupState();
}

class _CountFilterGroupState extends State<CountFilterGroup> with TickerProviderStateMixin {
  late List<AnimationController> _press, _select;
  late List<GlobalKey> _keys;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    final n = widget.filters.length;
    _keys = [for (var i = 0; i < n; i++) GlobalKey()];
    _press = [for (var i = 0; i < n; i++) AnimationController.unbounded(vsync: this)];
    _select = [
      for (var i = 0; i < n; i++) AnimationController.unbounded(vsync: this, value: i == widget.selected ? 1 : 0),
    ];
  }

  void _dispose() {
    for (final c in [..._press, ..._select]) {
      c.dispose();
    }
  }

  @override
  void didUpdateWidget(CountFilterGroup old) {
    super.didUpdateWidget(old);
    if (old.filters.length != widget.filters.length) {
      _dispose();
      _create();
      return;
    }
    if (old.selected != widget.selected) {
      final still = reducedMotion(context);
      for (var i = 0; i < _select.length; i++) {
        final target = i == widget.selected ? 1.0 : 0.0;
        still ? _select[i].value = target : springTo(_select[i], target, AppSprings.bouncy);
      }
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _hold(int i, bool down) {
    if (reducedMotion(context)) return;
    springTo(_press[i], down ? 1 : 0, down ? AppSprings.fastSpatial : AppSprings.bouncy);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = widget.filters.length;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final fits = box.maxWidth / n >= 120 * scale;
      return AnimatedBuilder(
        animation: Listenable.merge([..._press, ..._select]),
        builder: (context, _) {
          Widget sized(int i) {
            final s = _select[i].value, p = _press[i].value;
            if (fits) {
              final flex = ((1 + .42 * s + .22 * p).clamp(.7, 1.95) * 1000).round();
              return Expanded(flex: flex, child: _tile(i, n));
            }
            return SizedBox(width: 116 * scale * (1 + .28 * s + .12 * p), child: _tile(i, n));
          }

          // AgroLens history filter: 92 tall, taller only for large text.
          final row = ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 92),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < n; i++) ...[if (i > 0) const SizedBox(width: 5), sized(i)],
                ],
              ),
            ),
          );
          return fits ? row : SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
        },
      );
    },
  );

  Widget _tile(int i, int n) {
    final filter = widget.filters[i];
    final active = i == widget.selected;
    final s = _select[i].value, p = _press[i].value;
    final t = s.clamp(0.0, 1.0);
    final round = math.max(s, p * .7).clamp(0.0, 1.2);
    Radius r(double base) => Radius.circular((base + (28 - base) * round).clamp(8.0, 32.0));
    final border = RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.horizontal(start: r(i == 0 ? 28 : 10), end: r(i == n - 1 ? 28 : 10)),
    );
    final colors = filter.colors;
    final bg = Color.lerp(AppColors.low, colors.bg, t)!;
    final fg = Color.lerp(AppColors.ink, colors.fg, t)!;
    final badgeBg = Color.lerp(AppColors.highest, colors.fg.withValues(alpha: .18), t)!;
    final text = Theme.of(context).textTheme;
    return Semantics(
      key: _keys[i],
      button: true,
      selected: active,
      label: '${filter.label}: ${filter.count}',
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => _hold(i, true),
        onPointerUp: (_) => _hold(i, false),
        onPointerCancel: (_) => _hold(i, false),
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
                final origin = _keys[i].currentContext;
                if (origin != null && !active) {
                  final scheme = Theme.of(context).colorScheme;
                  ShapeBurst.show(
                    context,
                    origin: ShapeBurst.centerOf(origin),
                    count: 14,
                    colors: [colors.bg, colors.fg, scheme.primary, scheme.tertiary],
                  );
                }
                widget.onSelect(i);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CountUp(
                            filter.count,
                            style: text.headlineSmall?.copyWith(height: 1.05, fontFeatures: tabular, color: fg),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 26,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: badgeBg,
                              shape: ExpressiveShapeBorder(
                                filter.shape,
                                morph: (p * .6 + s * .25).clamp(0.0, 1.0),
                                rotation: (s * .85 + p * .4) * math.pi / 4,
                              ),
                            ),
                            child: Icon(filter.icon, size: 14, color: fg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      filter.label,
                      style: text.labelMedium?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
