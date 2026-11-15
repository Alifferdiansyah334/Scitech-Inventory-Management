part of 'borrower_home.dart';

/// Second hero card on Beranda: live status of the borrower's active loan
/// (or a quick 3-step summary when none is active), paired with the
/// stroke-drawn illustration on a bobbing soft shape.
class _StoryPage extends StatefulWidget {
  const _StoryPage({required this.active, required this.loan, required this.indicator, required this.onAction});
  final bool active;
  final Loan? loan;
  final Widget indicator;
  final VoidCallback onAction;

  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage> with SingleTickerProviderStateMixin {
  late final _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100));

  void _play() {
    if (reducedMotion(context)) {
      _draw.value = 1;
    } else if (widget.active) {
      _draw.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play();
  }

  @override
  void didUpdateWidget(_StoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
    if (!widget.active) _draw.stop();
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  String get _chipLabel {
    final loan = widget.loan;
    if (loan == null) return 'Alur cepat';
    if (loan.late || loan.status == 'overdue') return 'Perlu segera kembali';
    if (loan.status == 'approved') return 'Siap diambil';
    return 'Pinjaman aktif';
  }

  IconData get _chipIcon {
    final loan = widget.loan;
    if (loan == null) return Icons.flash_on_rounded;
    if (loan.late || loan.status == 'overdue') return Icons.priority_high_rounded;
    if (loan.status == 'approved') return Icons.check_circle_outline_rounded;
    return Icons.schedule_rounded;
  }

  String get _title {
    final loan = widget.loan;
    if (loan == null) return 'Pinjam dalam beberapa ketukan';
    if (loan.late || loan.status == 'overdue') return 'Pinjaman lewat tenggat';
    if (loan.status == 'approved') return 'Barang siap diambil';
    return 'Sedang Anda pinjam';
  }

  String _description() {
    final loan = widget.loan;
    if (loan == null) {
      return 'Pilih barang di katalog, tentukan tanggal kembali, lalu ambil setelah disetujui.';
    }
    final due = dayDate(loan.dueDate);
    if (loan.late || loan.status == 'overdue') {
      return '${loan.name} · ${loan.quantity} unit · tenggat $due.';
    }
    if (loan.status == 'approved') {
      return '${loan.name} · ${loan.quantity} unit · kembali paling lambat $due.';
    }
    return '${loan.name} · ${loan.quantity} unit · kembali $due.';
  }

  String get _action => widget.loan != null ? 'Lihat pinjaman' : 'Pilih barang';

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    const shape = ExpressiveShape.flower8;
    return TiltOnTouch(
      maxAngle: .03,
      child: DecoratedBox(
        decoration: BoxDecoration(color: pal.hero, borderRadius: BorderRadius.circular(34)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            children: [
              Positioned(
                right: -95,
                top: -100,
                child: Ambient(
                  period: const Duration(seconds: 38),
                  builder: (context, t, _) => Transform.rotate(
                    angle: t * 2 * math.pi,
                    child: SizedBox.square(
                      dimension: 240,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(color: pal.heroSoft, shape: ExpressiveShapeBorder(shape)),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: LayoutBuilder(
                  builder: (context, box) {
                    // story_page: copy beside the 158 art and the controls
                    // in one row; very narrow cards or large text stack.
                    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
                    final stacked = box.maxWidth < 300 || scale > 1.35;
                    final art = _art(context, shape);
                    final button = _HeroButton(
                      label: _action,
                      icon: Icons.arrow_forward_rounded,
                      trailing: true,
                      onPressed: widget.onAction,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (stacked) ...[
                          _copy(context, shape),
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerRight, child: art),
                        ] else
                          Row(
                            children: [
                              Expanded(child: _copy(context, shape)),
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
                            children: [widget.indicator, button],
                          )
                        else
                          Row(
                            children: [
                              widget.indicator,
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

  Widget _copy(BuildContext context, ExpressiveShape shape) {
    final pal = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: ShapeDecoration(color: pal.onHero.withValues(alpha: .14), shape: const StadiumBorder()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShapeIcon(
                  icon: _chipIcon,
                  shape: shape,
                  size: 20,
                  fill: pal.onHero,
                  foreground: pal.hero,
                  iconScale: .62,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _chipLabel,
                    style: context.text.labelSmall?.copyWith(color: pal.onHero, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        WordReveal(_title, style: _heroTitle(context)),
        const SizedBox(height: 8),
        Text(_description(), style: _heroBody(context)),
      ],
    );
  }

  /// 158×184 art column at full size; the caller scales it down.
  Widget _art(BuildContext context, ExpressiveShape shape) {
    final pal = context.palette;
    final on = pal.onHero;
    return SizedBox(
      width: 158,
      height: 184,
      child: Stack(
        children: [
          Positioned.fill(
            top: 10,
            child: Semantics(
              button: true,
              label: 'Ulangi ilustrasi',
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _play();
                },
                child: Stack(
                  children: [
                    Center(
                      child: Bob(
                        distance: 2.5,
                        turn: .025,
                        child: SizedBox.square(
                          dimension: 148,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(color: pal.heroSoft, shape: ExpressiveShapeBorder(shape)),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _StoryPainter(step: widget.loan == null ? 1 : 2, progress: _draw, ink: on),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Icon(Icons.replay_rounded, size: 16, color: on.withValues(alpha: .72)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
