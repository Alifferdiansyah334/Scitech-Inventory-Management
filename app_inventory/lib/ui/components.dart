import 'package:flutter/material.dart';
import 'springs.dart';
import 'tokens.dart';

/// Punched asset label carrying an item's short ID: the identity motif.
class AssetTag extends StatelessWidget {
  const AssetTag(this.id, {this.dark = false, this.prefix = 'ID ', super.key});
  final String id;
  final bool dark;
  final String prefix;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ID barang ${shortId(id)}',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: dark ? AppColors.navy : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark ? AppColors.navySoft : AppColors.navy,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$prefix${shortId(id)}',
            style: TextStyle(
              fontFamily: AppFonts.mono,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: dark ? Colors.white : AppColors.navy,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Larger, slightly rotated label card (login hero, receipts, empty states).
class AssetLabelCard extends StatelessWidget {
  const AssetLabelCard({
    required this.title,
    required this.subtitle,
    this.angle = 0,
    this.width = 200,
    super.key,
  });
  final String title, subtitle;
  final double angle, width;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330A1428),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

enum Tone { neutral, ok, waiting, bad, info }

({Color fg, Color bg}) toneColors(Tone tone) => switch (tone) {
  Tone.ok => (fg: AppColors.ok, bg: AppColors.okSoft),
  Tone.waiting => (fg: AppColors.accentText, bg: AppColors.accentSoft),
  Tone.bad => (fg: AppColors.bad, bg: AppColors.badSoft),
  Tone.info => (fg: AppColors.navy, bg: AppColors.navySoft),
  Tone.neutral => (fg: AppColors.muted, bg: AppColors.paper),
};

/// Tone for a loan status. Accent (waiting) marks something that waits on a
/// person or a deadline; status is always also spelled out as text.
Tone loanTone(String status, {bool late = false}) {
  if (late) return Tone.bad;
  return switch (status) {
    'pending' || 'returning' || 'needs_review' => Tone.waiting,
    'approved' || 'returned' => Tone.ok,
    'borrowed' => Tone.info,
    'overdue' || 'rejected' => Tone.bad,
    _ => Tone.neutral,
  };
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {this.tone = Tone.neutral, super.key});
  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Rounded square holding an icon (item placeholder, list leading).
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    this.size = 52,
    this.background = AppColors.navySoft,
    this.foreground = AppColors.navy,
    super.key,
  });
  final IconData icon;
  final double size;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Icon(icon, color: foreground, size: size * 0.48),
  );
}

/// White rounded surface separated by tone, not by outline.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surface,
    this.onTap,
    this.selected = false,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: selected
          ? const BorderSide(color: AppColors.navy, width: 2)
          : BorderSide.none,
    );
    final body = Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return onTap == null ? body : PressSpring(child: body);
  }
}

/// Round icon button used on navy headers (white on navy2) or on paper.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onDark = true,
    this.badge = false,
    super.key,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool onDark, badge;

  @override
  Widget build(BuildContext context) => PressSpring(
    enabled: onPressed != null,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: onDark ? AppColors.navy2 : AppColors.surface,
        foregroundColor: onDark ? Colors.white : AppColors.ink,
        disabledForegroundColor: onDark
            ? AppColors.navyMuted
            : AppColors.control,
        fixedSize: const Size(44, 44),
      ),
      icon: Badge(
        isLabelVisible: badge,
        backgroundColor: AppColors.accent,
        smallSize: 9,
        child: Icon(icon, size: 22),
      ),
    ),
  );
}

/// Navy header block with rounded bottom corners. Content placed right after
/// it can overlap upward with a negative offset (see [overlap]).
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
    this.overlap = 0,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Extra bottom space reserved for content that overlaps the header.
  final double overlap;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
    ),
    padding: padding.add(EdgeInsets.only(bottom: overlap)),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: IconTheme.merge(
        data: const IconThemeData(color: Colors.white),
        child: child,
      ),
    ),
  );
}

/// Empty or problem state that says why and offers the one next action.
class StateMessage extends StatelessWidget {
  const StateMessage({
    required this.title,
    required this.message,
    this.icon = Icons.search_off_rounded,
    this.action,
    super.key,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppColors.navySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: AppColors.navy),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

/// Section heading with an optional trailing action.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.trailing, super.key});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
