part of 'borrower_home.dart';

/// Two-card live operational hero on Beranda: page 0 is the live stock &
/// interactive category crate (immediately playable), page 1 summarises the
/// borrower's active loan or quick borrow flow.
class _HomeStory extends StatefulWidget {
  const _HomeStory({
    required this.categories,
    required this.ready,
    required this.active,
    required this.onCatalog,
    required this.onLoans,
  });
  final List<_Category> categories;
  final int ready;

  /// Loan waiting to be picked up or returned; summarised on step 3.
  final Loan? active;
  final void Function([String? category]) onCatalog;
  final VoidCallback onLoans;

  @override
  State<_HomeStory> createState() => _HomeStoryState();
}

class _HomeStoryState extends State<_HomeStory> {
  int _page = 0;

  void _go(int page) {
    if (page == _page) return;
    setState(() => _page = page);
  }

  void _openSecondCta() {
    widget.active == null ? widget.onCatalog() : widget.onLoans();
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Stok & rak kategori', 'Status pinjaman'];

    Widget indicator() => _StepDots(
      count: 2,
      current: _page,
      labels: labels,
      onSelect: (page) {
        HapticFeedback.selectionClick();
        _go(page);
      },
    );

    final card = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: _page == 0
          ? _CatalogHero(
              categories: widget.categories,
              ready: widget.ready,
              indicator: indicator(),
              onCatalog: widget.onCatalog,
            )
          : _StoryPage(active: true, loan: widget.active, indicator: indicator(), onAction: _openSecondCta),
    );
    // Content determines the hero height, including at large text sizes.
    // Horizontal swipes and the step controls both retain page navigation.
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final speed = details.primaryVelocity ?? 0;
        if (speed.abs() < 150) return;
        final next = (_page + (speed < 0 ? 1 : -1)).clamp(0, 1);
        if (next != _page) {
          HapticFeedback.selectionClick();
          _go(next);
        }
      },
      child: reducedMotion(context)
          ? card
          : AnimatedSize(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: card,
            ),
    );
  }
}

/// M3 Expressive step indicator: soft dots, the current step springs into a
/// turning expressive shape as the pages scroll.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.current, required this.labels, required this.onSelect});

  static const _shapes = [
    ExpressiveShape.flower8,
    ExpressiveShape.cookie9,
    ExpressiveShape.sunny8,
    ExpressiveShape.softBurst,
  ];

  final int count, current;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final on = context.palette.onHero;
    return DecoratedBox(
      decoration: ShapeDecoration(color: on.withValues(alpha: .14), shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < count; i++) _dot(on, i, current.toDouble())],
        ),
      ),
    );
  }

  Widget _dot(Color on, int i, double page) {
    final focus = (1.0 - (page - i).abs()).clamp(0.0, 1.0);
    final size = 8.0 + 11.0 * focus;
    return Semantics(
      button: true,
      selected: i == current,
      label: labels[i],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(i),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: Color.lerp(on.withValues(alpha: .4), on, focus),
                shape: ExpressiveShapeBorder(
                  ExpressiveShape.circle,
                  morphTo: _shapes[i % _shapes.length],
                  morph: focus,
                  rotation: focus * math.pi / 3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step card title (story_page: 20.5, w800, height 1.13).
TextStyle? _heroTitle(BuildContext context) => context.text.titleLarge?.copyWith(
  fontSize: 20.5,
  height: 1.13,
  fontWeight: FontWeight.w800,
  color: context.palette.onHero,
);

/// Cycling question on the shelf card (scan_hero: 21, w800, height 1.12).
TextStyle? _heroQuestion(BuildContext context) => context.text.headlineSmall?.copyWith(
  fontSize: 21,
  height: 1.12,
  fontWeight: FontWeight.w800,
  color: context.palette.onHero,
);

/// Hero body copy (12.5, height 1.38).
TextStyle? _heroBody(BuildContext context) =>
    context.text.bodySmall?.copyWith(fontSize: 12.5, height: 1.38, color: context.palette.onHero.withValues(alpha: .9));
