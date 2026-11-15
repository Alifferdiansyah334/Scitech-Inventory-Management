import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../ui/springs.dart';
import '../../core/brand.dart';
import '../../ui/theme.dart';
import 'auth_hero.dart';
import 'auth_parts.dart';

part 'auth_entry_brand.dart';
part 'auth_size_reporter.dart';

/// Shared auth layout: a quiet brand bar, sculptural tonal hero, then a
/// compact form. One scroll surface keeps errors and keyboard reachable.
class AuthFrame extends StatefulWidget {
  const AuthFrame({required this.step, super.key});
  final AuthStep step;

  @override
  State<AuthFrame> createState() => _AuthFrameState();
}

class _AuthFrameState extends State<AuthFrame> {
  double _dir = 1;

  /// Measured heights of the brand bar and the form block; the hero takes
  /// what the viewport has left.
  double _brandH = 0, _sheetH = 0;

  final _scroll = ScrollController();
  bool _typing = false;
  bool _restoring = false;
  int _focusRevision = 0;

  /// Restore only keyboard-driven scrolling, never the user's own drag.
  double? _restore;
  double _inset = 0;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (_inset > 0 && inset == 0) {
      final focus = FocusManager.instance.primaryFocus;
      final revision = _focusRevision;
      final restore = _restore;
      _restore = null;
      // Wait for the expanded viewport to clamp its scroll extent first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _inset > 0 || revision != _focusRevision) return;
        if (_typing && focus == FocusManager.instance.primaryFocus) focus?.unfocus();
        if (restore == null || !_scroll.hasClients) return;
        final target = restore.clamp(0.0, _scroll.position.maxScrollExtent);
        if ((_scroll.offset - target).abs() < .5) return;
        if (reducedMotion(context)) {
          _scroll.jumpTo(target);
        } else {
          _restoring = true;
          _scroll
              .animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic)
              .whenComplete(() => _restoring = false);
        }
      });
    }
    _inset = inset;
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _focusChanged() {
    _focusRevision++;
    final ctx = FocusManager.instance.primaryFocus?.context;
    final field =
        ctx != null &&
        ctx.mounted &&
        ctx.findAncestorStateOfType<EditableTextState>() != null &&
        ctx.findAncestorStateOfType<_AuthFrameState>() == this;
    if (field && !_typing && _inset == 0) {
      if (_restoring && _scroll.hasClients) _scroll.jumpTo(_scroll.offset);
      _restore = _scroll.hasClients ? _scroll.offset : 0;
    }
    _typing = field;
  }

  void _measured({double? brand, double? sheet}) {
    final b = brand ?? _brandH, s = sheet ?? _sheetH;
    if (!mounted || ((b - _brandH).abs() < .5 && (s - _sheetH).abs() < .5)) return;
    setState(() {
      _brandH = b;
      _sheetH = s;
    });
  }

  @override
  void didUpdateWidget(AuthFrame old) {
    super.didUpdateWidget(old);
    if (old.step.id != widget.step.id) {
      HapticFeedback.selectionClick();
      _dir = widget.step.stage >= old.step.stage ? 1 : -1;
    }
  }

  /// The step's fields; a new step slides in, a new mode of the same step
  /// grows or shrinks in place.
  Widget _form() {
    final form = AuthSwitch(
      direction: _dir,
      child: AutofillGroup(
        key: ValueKey('form-${widget.step.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.step.children),
      ),
    );
    if (reducedMotion(context)) return form;
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: form,
    );
  }

  /// Fields sit directly on the canvas, without a second containing card.
  Widget _sheetCard() {
    final footer = widget.step.footer;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _form(),
                const SizedBox(height: 10),
                widget.step.action,
                if (footer != null) ...[const SizedBox(height: 8), Center(child: footer)],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phone() {
    // Read above Scaffold: its body removes keyboard insets and changes safe
    // padding while the IME animates. Neither should resize the hero.
    final height = MediaQuery.sizeOf(context).height - MediaQuery.viewPaddingOf(context).vertical;
    final known = _brandH > 0 && _sheetH > 0;
    return SafeArea(
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction != ScrollDirection.idle) _restore = null;
          return false;
        },
        child: SingleChildScrollView(
          controller: _scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SizeReporter(
                onSize: (s) => _measured(brand: s.height),
                child: _brandBar(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AuthHero(
                  step: widget.step,
                  direction: _dir,
                  minHeight: known ? height - _brandH - _sheetH : null,
                ),
              ),
              _SizeReporter(
                onSize: (s) => _measured(sheet: s.height),
                child: _sheetCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wide() => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          children: [
            _brandBar(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 12, 24),
                        child: AuthHero(step: widget.step, direction: _dir, large: true),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(12, 16, 24, 24),
                        child: _sheetCard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(backgroundColor: context.colors.surface, body: wide ? _wide() : _phone()),
    );
  }
}
