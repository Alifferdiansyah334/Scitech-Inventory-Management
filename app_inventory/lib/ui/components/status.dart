part of '../components.dart';

enum Tone { neutral, ok, waiting, bad, info }

({Color fg, Color bg}) toneColors(Tone tone) => switch (tone) {
  Tone.ok => (fg: AppColors.onOkContainer, bg: AppColors.okContainer),
  Tone.waiting => (fg: AppColors.onDeadlineContainer, bg: AppColors.deadlineContainer),
  Tone.bad => (fg: AppColors.onErrorContainer, bg: AppColors.errorContainer),
  Tone.info => (fg: AppColors.onSecondary, bg: AppColors.secondary),
  Tone.neutral => (fg: AppColors.muted, bg: AppColors.high),
};

IconData? toneIcon(Tone tone) => switch (tone) {
  Tone.ok => Icons.check_rounded,
  Tone.waiting => Icons.schedule_rounded,
  Tone.bad => Icons.error_outline_rounded,
  Tone.info => Icons.inventory_2_outlined,
  Tone.neutral => null,
};

/// Tone for a loan status. Deadline orange marks something that waits on a
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

ExpressiveShape toneShape(Tone tone) => switch (tone) {
  Tone.ok => ExpressiveShape.circle,
  Tone.waiting => ExpressiveShape.sunny8,
  Tone.bad => ExpressiveShape.burst,
  Tone.info => ExpressiveShape.cookie9,
  Tone.neutral => ExpressiveShape.cookie9,
};

/// Status chip: a pill carrying a shaped badge (inverted colours) and the
/// status in words, so it reads without colour. [dense] for tight rows.
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {this.tone = Tone.neutral, this.showIcon = true, this.dense = false, super.key});
  final String label;
  final Tone tone;
  final bool showIcon, dense;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(tone);
    final icon = showIcon ? toneIcon(tone) : null;
    final badge = dense ? 16.0 : 20.0;
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        icon == null ? (dense ? 9 : 12) : (dense ? 4 : 5),
        dense ? 3 : 4,
        dense ? 9 : 12,
        dense ? 3 : 4,
      ),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(AppRadii.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ShapeIcon(
              icon: icon,
              shape: toneShape(tone),
              size: badge,
              fill: colors.fg,
              foreground: colors.bg,
              iconScale: .62,
            ),
            SizedBox(width: dense ? 4 : 6),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: colors.fg, fontSize: dense ? 12 : 13, fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon inside an expressive shape (item placeholder, list leading).
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    this.size = 48,
    this.background,
    this.foreground,
    this.shape = ExpressiveShape.cookie9,
    super.key,
  });
  final IconData icon;
  final double size;
  final Color? background, foreground;
  final ExpressiveShape shape;

  @override
  Widget build(BuildContext context) => ShapeIcon(
    icon: icon,
    shape: shape,
    size: size,
    fill: background ?? AppColors.fixed,
    foreground: foreground ?? AppColors.onFixed,
  );
}
