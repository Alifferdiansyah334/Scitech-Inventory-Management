part of '../controls.dart';

/// M3 Expressive search bar:
/// - every character typed pops a floating expressive shape with that letter
///   above the caret and spins/morphs the leading shape badge to the next
///   shape in the library;
/// - focusing morphs the bar's corners (`28` -> `18`) on a spring;
/// - the clear button sits in a `burst` shape that spins on press.
class ExpressiveSearchBar extends StatefulWidget {
  const ExpressiveSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    super.key,
  });
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<ExpressiveSearchBar> createState() => _ExpressiveSearchBarState();
}

class _ExpressiveSearchBarState extends State<ExpressiveSearchBar> with TickerProviderStateMixin {
  final _focus = FocusNode();
  final _rnd = math.Random();
  final List<_TypedGlyph> _glyphs = [];
  late final _focusCtrl = AnimationController.unbounded(vsync: this);
  late final _typePulse = AnimationController.unbounded(vsync: this);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  String _prev = '';
  int _step = 0;

  /// Bumped each glyph frame; only the glyph layer listens.
  final _glyphFrame = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _prev = widget.controller.text;
    _focus.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  void _onFocus() {
    final target = _focus.hasFocus ? 1.0 : 0.0;
    reducedMotion(context) ? _focusCtrl.value = target : springTo(_focusCtrl, target, AppSprings.bouncy);
  }

  void _onText() {
    final text = widget.controller.text;
    if (text == _prev) return;
    final added = text.length > _prev.length;
    final ch = added && text.isNotEmpty ? text.characters.last : '✦';
    _prev = text;
    if (!mounted) return;
    setState(() {});
    if (reducedMotion(context)) return;

    _step++;
    _typePulse.value = 0;
    springTo(_typePulse, 1, AppSprings.bouncy, velocity: 6);
    HapticFeedback.selectionClick();

    // Measure where the caret sits so the shape pops right out of the word.
    final style = context.text.bodyLarge ?? const TextStyle(fontSize: 16);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final boxWidth = (context.size?.width ?? 300) - 116;
    final caretX = 62 + painter.width.clamp(0.0, math.max(24.0, boxWidth));

    final scheme = context.colors;
    final palette = [
      (scheme.primary, scheme.onPrimary),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      (context.palette.hero, context.palette.onHero),
    ];
    final tone = palette[_step % palette.length];
    _glyphs.add(
      _TypedGlyph(
        char: ch.trim().isEmpty ? '•' : ch.toUpperCase(),
        x: caretX + (_rnd.nextDouble() - .5) * 14,
        shape: _shapeCycle[_step % _shapeCycle.length],
        color: tone.$1,
        onColor: tone.$2,
        driftX: (_rnd.nextDouble() - .5) * 44,
        spin: (_rnd.nextDouble() - .5) * 5,
      ),
    );
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
    _glyphFrame.value++;
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    for (final g in _glyphs) {
      g.age += dt;
    }
    _glyphs.removeWhere((g) => g.age >= 1.15);
    if (_glyphs.isEmpty) {
      _ticker.stop();
    }
    // Glyphs repaint in their own layer; the search bar is not rebuilt.
    if (mounted) _glyphFrame.value++;
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    widget.controller.removeListener(_onText);
    _focusCtrl.dispose();
    _typePulse.dispose();
    _ticker.dispose();
    _glyphFrame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final shapeNow = _shapeCycle[_step % _shapeCycle.length];
    final shapePrev = _shapeCycle[(_step - 1).clamp(0, 1 << 20) % _shapeCycle.length];
    final chars = widget.controller.text.characters.where((c) => c.trim().isNotEmpty).toList();
    final tones = [
      (scheme.primary, scheme.onPrimary),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      (context.palette.hero, context.palette.onHero),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_focusCtrl, _typePulse]),
              builder: (context, _) {
                final f = _focusCtrl.value.clamp(0.0, 1.2);
                final pulse = _typePulse.value.clamp(0.0, 1.3);
                final radius = BorderRadius.circular((28 - 10 * f).clamp(14, 30).toDouble());
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(scheme.surfaceContainerHigh, scheme.surfaceContainerLowest, f.clamp(0, 1)),
                    borderRadius: radius,
                    border: Border.all(
                      color: Color.lerp(scheme.outlineVariant.withValues(alpha: .4), scheme.primary, f.clamp(0, 1))!,
                      width: 1 + 1.2 * f.clamp(0, 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1 + .14 * (1 - (pulse - .5).abs() * 2).clamp(0, 1),
                          child: SizedBox.square(
                            dimension: 40,
                            child: DecoratedBox(
                              decoration: ShapeDecoration(
                                color: Color.lerp(scheme.secondaryContainer, scheme.primary, f.clamp(0, 1)),
                                shape: ExpressiveShapeBorder(
                                  shapePrev,
                                  morphTo: shapeNow,
                                  morph: pulse,
                                  rotation: (_step * .55) + pulse * .45,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: Color.lerp(scheme.onSecondaryContainer, scheme.onPrimary, f.clamp(0, 1)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focus,
                            onChanged: widget.onChanged,
                            style: context.text.bodyLarge,
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              filled: false,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        if (chars.isNotEmpty) ...[
                          _MiniShapeTrail(chars: chars, tones: tones, step: _step),
                          const SizedBox(width: 6),
                          PressSpring(
                            squash: .14,
                            scale: .88,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onClear();
                              },
                              child: ShapeIcon(
                                icon: Icons.close_rounded,
                                shape: ExpressiveShape.burst,
                                size: 36,
                                fill: scheme.errorContainer,
                                foreground: scheme.onErrorContainer,
                                iconScale: .5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _glyphFrame,
                    builder: (context, _, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [for (final g in _glyphs) _SearchTypingGlyph(glyph: g)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (chars.isNotEmpty) _SearchShapeLetters(chars: chars, tones: tones, step: _step),
      ],
    );
  }
}
