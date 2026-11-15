import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models.dart';
import '../../ui/motion.dart';
import '../../ui/physics.dart';
import '../../ui/playground.dart';
import '../../ui/shapes.dart';
import '../../ui/tokens.dart';
import '../home/inventory_jar.dart';
import 'actions.dart';

part 'queue_box.dart';

/// The Ringkasan hero, after AgroLens' scanner card: brand block radius 34
/// with two soft shapes turning slowly behind, a chip, the real number of
/// waiting requests, one line, and the queue box on the right: one shaped
/// ball per waiting request (tap a ball to open it, drag to toss, tap the
/// box rim to shake). The white 'Tinjau' pill sits bottom right.
class QueueHero extends StatelessWidget {
  const QueueHero({
    required this.actions,
    required this.pending,
    required this.late,
    required this.loading,
    required this.onReview,
    required this.onOpen,
    super.key,
  });
  final WorkspaceActions actions;
  final List<Loan> pending;
  final int late;
  final bool loading;
  final VoidCallback? onReview;
  final ValueChanged<Loan> onOpen;

  @override
  Widget build(BuildContext context) {
    final on = AppColors.onHero;
    final text = Theme.of(context).textTheme;
    final scroll = Scrollable.maybeOf(context)?.position;
    Widget blob(double size, ExpressiveShape shape, double speed, double scrollFactor) => Ambient(
      period: Duration(seconds: (40 / speed.abs()).round()),
      builder: (context, t, _) => Transform.rotate(
        angle:
            t * 2 * math.pi * (speed > 0 ? 1 : -1) +
            (scroll != null && scroll.hasPixels ? scroll.pixels * scrollFactor : 0),
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: ShapeDecoration(color: AppColors.heroSoft, shape: ExpressiveShapeBorder(shape)),
          ),
        ),
      ),
    );
    final count = pending.length;
    final line = loading
        ? 'Memuat permintaan dari server.'
        : count == 0
        ? 'Tidak ada yang menunggu. Semua permintaan sudah ditangani.'
        : 'permintaan menunggu keputusan Anda. Ketuk bola untuk meninjau.';
    return TiltOnTouch(
      maxAngle: .03,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppColors.hero, borderRadius: BorderRadius.circular(34)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            children: [
              Positioned(
                right: -105,
                top: -115,
                child: ExcludeSemantics(child: blob(270, ExpressiveShape.softBurst, 1, .004)),
              ),
              Positioned(
                left: -75,
                bottom: 20,
                child: ExcludeSemantics(child: blob(170, ExpressiveShape.cookie9, -1.4, -.006)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, box) {
                        // Side by side as on AgroLens' scan hero; stacked
                        // only when the copy column would get too narrow.
                        final stacked = box.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(16) > 21.6;
                        final copy = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroChip(
                              icon: count > 0 ? Icons.pending_actions_rounded : Icons.task_alt_rounded,
                              label: 'Antrean',
                            ),
                            const SizedBox(height: 10),
                            WordReveal(
                              count == 0 ? 'Semua beres!' : 'Siap ditinjau',
                              key: ValueKey(count == 0),
                              style: text.headlineSmall!.copyWith(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: on,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CountUp(
                              count,
                              style: text.displaySmall?.copyWith(
                                color: on,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: -1,
                                fontFeatures: tabular,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              line,
                              style: text.bodySmall?.copyWith(
                                fontSize: 12.5,
                                height: 1.38,
                                color: on.withValues(alpha: .9),
                              ),
                            ),
                          ],
                        );
                        final tray = _QueueBox(actions: actions, pending: pending, onOpen: onOpen);
                        return stacked
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  copy,
                                  const SizedBox(height: 12),
                                  Align(alignment: Alignment.centerRight, child: tray),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: copy),
                                  const SizedBox(width: 8),
                                  tray,
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        if (late > 0) _HeroChip(icon: Icons.priority_high_rounded, label: '$late terlambat'),
                        if (onReview != null) _ReviewButton(onPressed: onReview!, empty: count == 0),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White call to action that breathes gently, as on AgroLens' hero.
class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.onPressed, required this.empty});
  final VoidCallback onPressed;
  final bool empty;

  @override
  Widget build(BuildContext context) => Ambient(
    period: const Duration(milliseconds: 2400),
    builder: (context, t, child) => Transform.scale(scale: 1 + .015 * math.sin(t * 2 * math.pi), child: child),
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandInk,
        minimumSize: const Size(146, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      icon: Bob(
        distance: 0,
        turn: .18,
        period: const Duration(milliseconds: 1200),
        child: Icon(empty ? Icons.list_alt_rounded : Icons.fact_check_rounded, size: 19),
      ),
      label: Text(empty ? 'Lihat pinjaman' : 'Tinjau'),
    ),
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final on = AppColors.onHero;
    return DecoratedBox(
      decoration: ShapeDecoration(color: on.withValues(alpha: .14), shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: on),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: on),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
