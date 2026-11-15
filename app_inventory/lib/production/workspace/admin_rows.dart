import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/button_feedback.dart';
import '../../ui/components.dart';
import '../../ui/physics.dart';
import '../../ui/shapes.dart';
import '../../ui/springs.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

part 'admin_rows_avatar.dart';

String _initials(String name) {
  final letters = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
  return letters.isEmpty ? '?' : letters;
}

/// Subtitle under the page title (styled by [SectionLayout]).
Widget sectionSummary(BuildContext context, String text) => Text(text, style: TextStyle(fontFeatures: tabular));

/// Filter chips that scroll sideways instead of wrapping.
class ChipStrip extends StatelessWidget {
  const ChipStrip({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: AppSpace.sm), children[i]],
      ],
    ),
  );
}

/// Top of an admin list (AgroLens library recipe): the search bar (with
/// [action] beside it on wide layouts), the filter strip, then the results
/// as a section heading.
class AdminListHeader extends StatelessWidget {
  const AdminListHeader({required this.search, required this.caption, this.chips, this.action, super.key});
  final Widget search;
  final String caption;
  final Widget? chips, action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (action != null)
        Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: AppSpace.md),
            action!,
          ],
        )
      else
        search,
      if (chips != null) ...[const SizedBox(height: AppSpace.md), chips!],
      SectionTitle(caption),
    ],
  );
}

/// Shaped 38 dp row action of the AgroLens 'Kelola artikel' rows (edit
/// cookie9, delete burst): springs and turns while held. The hit area is
/// 44×48 so the shapes still sit 6 apart.
class ShapeAction extends StatelessWidget {
  const ShapeAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.shape = ExpressiveShape.cookie9,
    this.danger = false,
    this.fill,
    this.foreground,
    super.key,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ExpressiveShape shape;
  final bool danger;
  final Color? fill, foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final enabled = onPressed != null;
    final bg = !enabled ? AppColors.disabled : fill ?? (danger ? scheme.errorContainer : scheme.secondaryContainer);
    final fg = !enabled
        ? AppColors.onDisabled
        : foreground ?? (danger ? scheme.onErrorContainer : scheme.onSecondaryContainer);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: PressSpring(
          enabled: enabled,
          scale: .9,
          squash: .14,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tactileTap(onPressed),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              child: ShapeIcon(icon: icon, shape: shape, size: 38, fill: bg, foreground: fg, iconScale: .48),
            ),
          ),
        ),
      ),
    );
  }
}

/// One record in the AgroLens 'Kelola artikel' row recipe: white card
/// radius 24, padding 10, a 60 shaped [leading], gap 12, a one-line title,
/// a muted meta line, optional [pills] and the shaped [actions] at the end.
/// Tapping the row runs [onTap] (usually the edit action).
class ManageRow extends StatelessWidget {
  const ManageRow({
    required this.leading,
    required this.title,
    required this.meta,
    this.pills = const [],
    this.actions = const [],
    this.onTap,
    super.key,
  });
  final Widget leading;
  final String title, meta;
  final List<Widget> pills, actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, fontFeatures: tabular),
                ),
                if (pills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: pills,
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[const SizedBox(width: 3), ...actions],
        ],
      ),
    );
  }
}

/// Picture clipped to the category shape (AgroLens crop photo), or the
/// category shape and icon on its tint when there is no picture.
class ShapedThumb extends StatelessWidget {
  const ShapedThumb({
    required this.category,
    required this.imageUrl,
    required this.picture,
    this.size = 60,
    this.enabled = true,
    super.key,
  });
  final String category, imageUrl;
  final Widget Function(String) picture;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final thumb = imageUrl.isEmpty
        ? ShapeIcon.category(category, size: size)
        : SizedBox.square(
            dimension: size,
            child: ShapeClip(shape: categoryStyle(category).shape, child: picture(imageUrl)),
          );
    return enabled ? thumb : Opacity(opacity: .55, child: thumb);
  }
}

/// Cards 8 apart: one column on phones, two from 720 wide, three from 1100.
class AdminGrid extends StatelessWidget {
  const AdminGrid({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = AppSpace.sm;
      final columns = box.maxWidth >= 1100
          ? 3
          : box.maxWidth >= 720
          ? 2
          : 1;
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

/// Empty list (AgroLens history_empty): a flower shape of 112 that can be
/// tugged around, the title, why it is empty and the one next action.
class AdminEmpty extends StatelessWidget {
  const AdminEmpty({required this.title, required this.message, required this.icon, this.action, super.key});
  final String title, message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        children: [
          SpringDraggable(
            reach: 110,
            child: PressSpring(
              squash: .12,
              child: ShapeIcon(
                icon: icon,
                shape: ExpressiveShape.flower8,
                size: 112,
                fill: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
                iconScale: .4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
