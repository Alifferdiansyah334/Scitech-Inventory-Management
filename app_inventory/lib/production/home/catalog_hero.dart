part of 'borrower_home.dart';

/// Last story card (AgroLens scanner hero): ready units chip, a question
/// cycling through the categories, the shelf of category balls on the right
/// and a breathing white 'Cari barang' button. Soft blobs drift behind and
/// turn with the page scroll.
class _CatalogHero extends StatelessWidget {
  const _CatalogHero({required this.categories, required this.ready, required this.indicator, required this.onCatalog});
  final List<_Category> categories;
  final int ready;
  final Widget indicator;
  final void Function([String? category]) onCatalog;

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final scroll = Scrollable.maybeOf(context)?.position;
    Widget blob(double size, ExpressiveShape shape, double speed, double drift) => Ambient(
      period: Duration(seconds: (40 / speed.abs()).round()),
      builder: (context, t, _) => Transform.rotate(
        angle: t * 2 * math.pi * speed.sign + (scroll != null && scroll.hasPixels ? scroll.pixels * drift : 0),
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: ShapeDecoration(color: pal.heroSoft, shape: ExpressiveShapeBorder(shape)),
          ),
        ),
      ),
    );

    return TiltOnTouch(
      maxAngle: .03,
      child: DecoratedBox(
        decoration: BoxDecoration(color: pal.hero, borderRadius: BorderRadius.circular(34)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            children: [
              Positioned(right: -105, top: -115, child: blob(270, ExpressiveShape.softBurst, 1, .004)),
              Positioned(left: -75, bottom: 20, child: blob(170, ExpressiveShape.cookie9, -1.4, -.006)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: LayoutBuilder(
                  builder: (context, box) {
                    // scan_hero: copy beside the 142 crate and the controls
                    // in one row; very narrow cards or large text stack.
                    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
                    final stacked = box.maxWidth < 300 || scale > 1.35;
                    final copy = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroChip(icon: Icons.inventory_2_outlined, label: '$ready unit siap'),
                        const SizedBox(height: 10),
                        _CyclingQuestion(categories),
                        const SizedBox(height: 6),
                        Text(
                          categories.isEmpty
                              ? 'Rak masih kosong. Tarik ke bawah untuk memuat ulang.'
                              : 'Ketuk kategori di rak untuk membuka katalog, atau tekan tombol di bawah.',
                          style: _heroBody(context),
                        ),
                      ],
                    );
                    final art = _ShelfPit(categories: categories, onCatalog: onCatalog);
                    final button = _HeroButton(
                      label: 'Buka katalog',
                      icon: Icons.inventory_2_rounded,
                      onPressed: () => onCatalog(),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (stacked) ...[
                          copy,
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerRight, child: art),
                        ] else
                          Row(
                            children: [
                              Expanded(child: copy),
                              const SizedBox(width: 8),
                              art,
                            ],
                          ),
                        const SizedBox(height: 12),
                        if (stacked)
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [indicator, button],
                          )
                        else
                          Row(
                            children: [
                              indicator,
                              const SizedBox(width: 12),
                              Expanded(
                                child: Align(alignment: Alignment.centerRight, child: button),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The hero question, cycling through the shelf's categories. Each new
/// question swipes in from the right on a spatial spring while the old one
/// swipes out to the left, like turning a card.
class _CyclingQuestion extends StatefulWidget {
  const _CyclingQuestion(this.categories);
  final List<_Category> categories;

  @override
  State<_CyclingQuestion> createState() => _CyclingQuestionState();
}

class _CyclingQuestionState extends State<_CyclingQuestion> {
  Timer? _timer;
  int _i = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    _timer = reducedMotion(context) || widget.categories.isEmpty
        ? null
        : Timer.periodic(const Duration(milliseconds: 3400), (_) {
            if (mounted && TickerMode.valuesOf(context).enabled) {
              setState(() => _i++);
            }
          });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = ['Mau pinjam apa hari ini?', for (final c in widget.categories) 'Butuh ${c.name.toLowerCase()}?'];
    final text = questions[_i % questions.length];
    final still = reducedMotion(context);
    // A steady 54 tall slot (taller only when large text needs it), so the
    // card does not jump as the questions change. The clip keeps the
    // swiping text inside the copy column.
    return ClipRect(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: AnimatedSwitcher(
          duration: still ? Duration.zero : defaultSpatialCurve.duration,
          reverseDuration: still ? Duration.zero : const Duration(milliseconds: 260),
          layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
          transitionBuilder: (child, animation) {
            final incoming = child.key == ValueKey(text);
            // Incoming rides the spatial spring (slight overshoot); the
            // outgoing question leaves on its own accelerating curve.
            final curved = incoming
                ? CurvedAnimation(parent: animation, curve: defaultSpatialCurve)
                : CurvedAnimation(parent: animation, curve: Curves.easeInCubic);
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: const Interval(0, .6)),
              child: SlideTransition(
                position: Tween(begin: Offset(incoming ? .55 : -.55, 0), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
          child: Align(
            key: ValueKey(text),
            alignment: Alignment.topLeft,
            child: Text(text, style: _heroQuestion(context)),
          ),
        ),
      ),
    );
  }
}

/// Pill call to action on the hero. The step cards use the hero's
/// foreground with the arrow after the label (124×46); the shelf card uses
/// white with a bobbing leading icon (146×46) and breathes gently.
class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.icon, required this.onPressed, this.trailing = false});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final button = FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: trailing ? pal.onHero : Colors.white,
        foregroundColor: trailing ? pal.hero : pal.ink,
        minimumSize: Size(trailing ? 124 : 146, 46),
        padding: EdgeInsets.symmetric(horizontal: trailing ? 18 : 20),
        textStyle: trailing ? null : context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      iconAlignment: trailing ? IconAlignment.end : IconAlignment.start,
      icon: trailing
          ? Icon(icon, size: 18)
          : Bob(distance: 0, turn: .18, period: const Duration(milliseconds: 1200), child: Icon(icon, size: 19)),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    );
    if (trailing) return button;
    return Ambient(
      period: const Duration(milliseconds: 2400),
      builder: (context, t, child) => Transform.scale(scale: 1 + .015 * math.sin(t * 2 * math.pi), child: child),
      child: button,
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final on = context.palette.onHero;
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
                style: context.text.labelMedium?.copyWith(color: on),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
