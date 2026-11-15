part of 'queue_hero.dart';

/// The queue box: a translucent tray holding one shaped ball per waiting
/// request (at most nine), or a single check ball when nothing waits.
class _QueueBox extends StatefulWidget {
  const _QueueBox({required this.actions, required this.pending, required this.onOpen});
  final WorkspaceActions actions;
  final List<Loan> pending;
  final ValueChanged<Loan> onOpen;

  @override
  State<_QueueBox> createState() => _QueueBoxState();
}

class _QueueBoxState extends State<_QueueBox> {
  static const _max = 9;
  final _shake = ValueNotifier<int>(0);
  List<PitBall> _last = const [];
  String _lastKey = '';

  /// Keeps each ball's position and spin across rebuilds of the same queue.
  List<PitBall> _carry(String key, List<PitBall> balls) {
    if (key == _lastKey && balls.length == _last.length) {
      for (var i = 0; i < balls.length; i++) {
        balls[i].copyStateFrom(_last[i]);
      }
    }
    _lastKey = key;
    return _last = balls;
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Widget _ball(Loan loan, double radius) {
    final on = AppColors.onHero;
    final item = widget.actions.app.items.where((i) => i.id == loan.itemId).firstOrNull;
    final style = categoryStyle(item?.category ?? '');
    final (fill, ink) = AppColors.category(style.tone);
    return DecoratedBox(
      decoration: ShapeDecoration(color: on, shape: ExpressiveShapeBorder(style.shape)),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: item != null && item.imageUrl.isNotEmpty
            ? ShapeClip(shape: style.shape, child: widget.actions.picture(item.imageUrl))
            : ShapeIcon(icon: style.icon, shape: style.shape, size: radius * 2 - 5, fill: fill, foreground: ink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final on = AppColors.onHero;
    final shown = widget.pending.take(_max).toList();
    final radius = shown.length <= 3
        ? 24.0
        : shown.length <= 6
        ? 20.0
        : 16.0;
    final key = shown.map((l) => l.id).join();
    final balls = _carry(
      key,
      shown.isEmpty
          ? [
              PitBall(
                radius: 28,
                child: ShapeIcon(
                  icon: Icons.check_rounded,
                  shape: ExpressiveShape.flower8,
                  size: 56,
                  fill: on,
                  foreground: AppColors.hero,
                ),
              ),
            ]
          : [
              for (final loan in shown)
                PitBall(
                  radius: radius,
                  label: 'Tinjau ${loan.name}',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onOpen(loan);
                  },
                  child: _ball(loan, radius),
                ),
            ],
    );
    return SizedBox(
      width: 142,
      height: 186,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            right: 2,
            top: 18,
            bottom: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(22)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [on.withValues(alpha: .08), on.withValues(alpha: .16)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: BallPit(
                      key: ValueKey(key),
                      balls: balls,
                      height: 142,
                      shakeOnEmptyTap: true,
                      shakeTrigger: _shake,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: CrateFramePainter(ink: on)),
            ),
          ),
          // Tapping the lid shakes the queue crate.
          Positioned(
            left: 10,
            right: 10,
            top: 0,
            height: 28,
            child: Semantics(
              button: true,
              label: 'Kocok kotak antrean',
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _shake.value++),
            ),
          ),
          if (widget.pending.length > _max)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: on, shape: const StadiumBorder()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    '+${widget.pending.length - _max}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.hero, fontFeatures: tabular),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
