part of '../controls.dart';

class _ExpressiveTextFieldState extends State<ExpressiveTextField> with TickerProviderStateMixin {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());
  final _rnd = math.Random();
  final List<_TypedGlyph> _glyphs = [];

  /// Bumped each glyph frame; only the glyph layer listens.
  final _glyphFrame = ValueNotifier<int>(0);
  late final _focusCtrl = AnimationController.unbounded(vsync: this);
  late final _pulse = AnimationController.unbounded(vsync: this);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  String _prev = '';
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.controller.text;
    _focus.addListener(_onFocus);
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(ExpressiveTextField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
      _prev = widget.controller.text;
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (!mounted) return;
    final target = _focus.hasFocus ? 1.0 : 0.0;
    reducedMotion(context) ? _focusCtrl.value = target : springTo(_focusCtrl, target, AppSprings.bouncy);
  }

  String _shown(String ch) => widget.obscureText ? '•' : (ch.trim().isEmpty ? '•' : ch.toUpperCase());

  void _onText() {
    final text = widget.controller.text;
    if (text == _prev) return;
    final added = text.length > _prev.length;
    final ch = added && text.isNotEmpty ? text.characters.last : '✦';
    _prev = text;
    if (!mounted) return;
    // Only the word count reads the text in this widget; the field itself
    // follows the controller, so rebuild just when a count is shown.
    if (widget.showWordCount ?? widget.minLines >= 2) setState(() {});
    if (reducedMotion(context)) return;
    _step++;
    _pulse.value = 0;
    springTo(_pulse, 1, AppSprings.bouncy, velocity: 5.5);
    final width = (context.size?.width ?? 280) - 64;
    final x = 32 + ((text.length * 11) % math.max(40.0, width));
    final scheme = context.colors;
    final pal = context.palette;
    final tones = [
      (pal.hero, pal.onHero),
      (scheme.primary, scheme.onPrimary),
      (scheme.tertiary, scheme.onTertiary),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
    ];
    final tone = tones[_step % tones.length];
    _glyphs.add(
      _TypedGlyph(
        char: added ? _shown(ch) : '✦',
        x: x + (_rnd.nextDouble() - .5) * 18,
        shape: _shapeCycle[(_step + widget.shape.index) % _shapeCycle.length],
        color: tone.$1,
        onColor: tone.$2,
        driftX: (_rnd.nextDouble() - .5) * 42,
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
    if (_glyphs.isEmpty) _ticker.stop();
    // Glyphs repaint in their own layer; the text field is not rebuilt.
    if (mounted) _glyphFrame.value++;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    widget.controller.removeListener(_onText);
    _focusCtrl.dispose();
    _pulse.dispose();
    _glyphFrame.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final multi = !widget.obscureText && (widget.maxLines == null || widget.maxLines! > 1);
    final raw = widget.controller.text;
    final words = raw.trim().isEmpty ? 0 : raw.trim().split(RegExp(r'\s+')).length;
    final mins = (words / 200).ceil().clamp(1, 99);
    final counts = widget.showWordCount ?? widget.minLines >= 2;
    final String? statText = !counts || words == 0
        ? null
        : widget.minLines >= 4
        ? '$words kata · ~$mins mnt'
        : '$words kata';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PressSpring(
          enabled: widget.enabled,
          scale: .985,
          child: AnimatedBuilder(
            animation: _focusCtrl,
            builder: (context, _) {
              final ft = _focusCtrl.value;
              final t = ft.clamp(0.0, 1.0);
              final radius = BorderRadius.circular(((multi ? 28 : 24) - 8 * ft).clamp(12.0, 30.0));
              _TonalFieldBorder border(Color color, double width) => _TonalFieldBorder(
                borderRadius: radius,
                borderSide: width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
              );
              return TextFormField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                minLines: widget.obscureText ? 1 : widget.minLines,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                maxLength: widget.maxLength,
                textCapitalization: widget.capitalization,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                inputFormatters: widget.inputFormatters,
                obscureText: widget.obscureText,
                obscuringCharacter: '•',
                enableSuggestions: !widget.obscureText,
                autocorrect: !widget.obscureText,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onFieldSubmitted,
                onTapAlwaysCalled: true,
                onTap: widget.enabled ? HapticFeedback.selectionClick : null,
                onTapOutside: (_) => _focus.unfocus(),
                scrollPadding: const EdgeInsets.all(32),
                style: context.text.bodyLarge?.copyWith(height: multi ? 1.5 : null),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  alignLabelWithHint: multi,
                  labelStyle: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  floatingLabelStyle: context.text.labelLarge?.copyWith(color: scheme.primary),
                  hintStyle: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: .6)),
                  filled: true,
                  fillColor: Color.lerp(scheme.surfaceContainerLow, scheme.secondaryContainer, t * .35),
                  contentPadding: EdgeInsets.fromLTRB(18, multi ? 14 : 12, 18, multi ? 14 : 12),
                  errorMaxLines: 3,
                  counter: statText == null
                      ? null
                      : Text(statText, style: context.text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  counterText: statText == null ? '' : null,
                  border: border(Colors.transparent, 0),
                  enabledBorder: border(Colors.transparent, 0),
                  disabledBorder: border(Colors.transparent, 0),
                  focusedBorder: border(scheme.primary, 2),
                  errorBorder: border(scheme.error, 1.5),
                  focusedErrorBorder: border(scheme.error, 2),
                  prefixIconConstraints: const BoxConstraints(minWidth: 62, minHeight: 60),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        // Typing pops the badge: 0 → peak → 0 as the pulse
                        // springs to 1; only the badge rebuilds.
                        animation: _pulse,
                        builder: (context, badge) {
                          final p = _pulse.value.clamp(0.0, 1.3);
                          return Transform.scale(
                            scale: 1 + .16 * (1 - ((p - .5).abs() * 2)).clamp(0.0, 1.0),
                            child: badge,
                          );
                        },
                        child: Transform.rotate(
                          angle: ft * .2,
                          child: ShapeIcon(
                            icon: widget.icon,
                            shape: widget.shape,
                            size: 36,
                            fill: Color.lerp(scheme.secondaryContainer, scheme.primary, t),
                            foreground: Color.lerp(scheme.onSecondaryContainer, scheme.onPrimary, t),
                          ),
                        ),
                      ),
                    ),
                  ),
                  suffixIcon: widget.trailing,
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ValueListenableBuilder<int>(
                valueListenable: _glyphFrame,
                builder: (context, _, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [for (final g in _glyphs) _EditorTypingGlyph(glyph: g)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
