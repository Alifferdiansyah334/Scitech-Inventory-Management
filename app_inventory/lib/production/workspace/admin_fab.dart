import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';

/// Phone-only extended FAB of AgroLens 'Kelola artikel' (radius 24, a 36
/// add badge, spring .92/.12, a burst of 16 shapes and a light tap). The
/// pages live inside the shell's list, so the button floats in the
/// navigator overlay just above the end of the scroll view (the nav bar);
/// routes, sheets and dialogs pushed on top cover it. Leave room for it
/// with [AdminFab.clearance] at the end of the list.
class AdminFab extends StatefulWidget {
  const AdminFab({required this.label, required this.onPressed, this.icon = Icons.add_rounded, super.key});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Space to keep below the last row so the button never hides it.
  static const clearance = 92.0;

  @override
  State<AdminFab> createState() => _AdminFabState();
}

class _AdminFabState extends State<AdminFab> {
  final _portal = OverlayPortalController();
  double? _bottom, _end;

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  /// Distance from the overlay's bottom/end to the scroll view's; read after
  /// layout, so it follows the nav bar, insets and the keyboard.
  void _measure(Duration _) {
    if (!mounted) return;
    final scroll = Scrollable.maybeOf(context)?.context.findRenderObject();
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    if (scroll is! RenderBox || overlay is! RenderBox) return;
    if (!scroll.hasSize || !overlay.hasSize) return;
    final corner = overlay.globalToLocal(scroll.localToGlobal(scroll.size.bottomRight(Offset.zero)));
    final bottom = math.max(0.0, overlay.size.height - corner.dy);
    final end = math.max(0.0, overlay.size.width - corner.dx);
    if (bottom != _bottom || end != _end) {
      setState(() {
        _bottom = bottom;
        _end = end;
      });
    }
  }

  void _tap(BuildContext badge) {
    final scheme = context.colors;
    HapticFeedback.lightImpact();
    ShapeBurst.show(
      context,
      origin: ShapeBurst.centerOf(badge),
      count: 16,
      colors: [scheme.primary, scheme.tertiary, scheme.secondary, context.palette.hero],
    );
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt (and re-measured) when the window or the keyboard changes.
    MediaQuery.sizeOf(context);
    MediaQuery.viewInsetsOf(context);
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (_) {
        if (_bottom == null) {
          return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
        }
        return Positioned(right: _end! + 16, bottom: _bottom! + 16, child: _button());
      },
      child: const SizedBox.shrink(),
    );
  }

  Widget _button() {
    final scheme = context.colors;
    final enabled = widget.onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Semantics(
        container: true,
        button: true,
        enabled: enabled,
        child: PressSpring(
          enabled: enabled,
          scale: .92,
          squash: .12,
          child: Builder(
            builder: (badge) => Material(
              color: scheme.primaryContainer,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? () => _tap(badge) : null,
                enableFeedback: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShapeIcon(
                        icon: widget.icon,
                        shape: ExpressiveShape.cookie12,
                        size: 36,
                        fill: scheme.primary,
                        foreground: scheme.onPrimary,
                        iconScale: .6,
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .6),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
