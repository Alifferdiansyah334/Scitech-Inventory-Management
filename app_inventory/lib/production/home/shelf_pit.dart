part of 'borrower_home.dart';

/// Glass storage crate ("rak") holding one physics ball per category (the
/// AgroLens crop jar): tap a ball to open Katalog on that category, drag to
/// toss it, tap the lid to shake the crate.
class _ShelfPit extends StatefulWidget {
  const _ShelfPit({required this.categories, required this.onCatalog});
  final List<_Category> categories;
  final void Function([String? category]) onCatalog;

  /// Most balls the crate holds; the rest are a tap away in Katalog.
  static const capacity = 8;

  @override
  State<_ShelfPit> createState() => _ShelfPitState();
}

class _ShelfPitState extends State<_ShelfPit> {
  List<PitBall> _balls = const [];
  String _filled = '';

  List<_Category> get _shown => widget.categories.take(_ShelfPit.capacity).toList();

  String get _signature => _shown.map((c) => c.name).join('|');

  void _fill() {
    final on = context.palette.onHero;
    final shown = _shown;
    final old = _balls;
    _filled = _signature;
    // Fill about half the crate whatever the number of categories.
    final base = InventoryCrate.ballRadius(shown.length);
    _balls = [
      for (final (i, c) in shown.indexed)
        PitBall(
          radius: i.isOdd ? base * .94 : base,
          label: 'Buka kategori ${c.name}',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onCatalog(c.name);
          },
          child: InventoryCrate.ball(on, c.name),
        ),
    ];
    if (old.length == _balls.length) {
      for (var i = 0; i < old.length; i++) {
        _balls[i].copyStateFrom(old[i]);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fill();
  }

  @override
  void didUpdateWidget(_ShelfPit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature != _filled) _fill();
  }

  @override
  Widget build(BuildContext context) => InventoryCrate(
    // A different set of categories is placed afresh.
    pitKey: ValueKey(_signature),
    balls: _balls,
    shakeLabel: 'Kocok rak kategori',
  );
}
