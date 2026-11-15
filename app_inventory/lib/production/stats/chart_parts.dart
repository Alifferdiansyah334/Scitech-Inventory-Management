import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/shapes.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// Chart series colours from the palette roles: brand for the main series,
/// a softened brand for the second one, ok for ready stock, deadline orange
/// only for late loans and error only for failures. Meaning is always
/// repeated in a text legend with a shape marker.
abstract final class ChartColors {
  static Color get main => AppColors.brand;

  /// Second series next to [main]: brand mixed halfway into the card colour,
  /// so it follows the scheme in light and dark.
  static Color get soft => Color.lerp(AppColors.brand, AppColors.card, .5)!;
  static Color get neutral => AppColors.outline;
  static Color get ok => AppColors.ok;
  static Color get overdue => AppColors.deadline;
  static Color get failed => AppColors.error;
  static Color get track => AppColors.highest;
  static Color get grid => AppColors.line;
}

/// Stable legend shapes of the two stock series.
abstract final class ChartShapes {
  static const main = ExpressiveShape.cookie9;
  static const soft = ExpressiveShape.clover4;
}

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// "7 Nov"
String dayMonth(DateTime date) => '${date.day} ${_monthNames[date.month - 1]}';

/// Chart in the AgroLens settings group (radius 28, padding 16): a shaped
/// 40 badge, the title and the period as the value pill, the question it
/// answers, an optional legend row, then the chart.
class ChartCard extends StatelessWidget {
  const ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.period,
    this.legend,
    this.icon = Icons.insights_rounded,
    this.shape = ExpressiveShape.cookie9,
    super.key,
  });
  final String title, subtitle;
  final String? period;
  final Widget child;
  final IconData icon;
  final ExpressiveShape shape;

  /// Legend shown between the subtitle and the chart.
  final Widget? legend;

  @override
  Widget build(BuildContext context) => GroupCard(
    title: title,
    icon: icon,
    shape: shape,
    value: period,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(subtitle, style: context.text.bodySmall?.copyWith(height: 1.45, color: AppColors.muted)),
        if (legend != null) ...[const SizedBox(height: AppSpace.md), legend!],
        const SizedBox(height: AppSpace.lg + 4),
        child,
      ],
    ),
  );
}

/// Empty chart body that says why there is nothing to draw.
class ChartEmpty extends StatelessWidget {
  const ChartEmpty(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 140),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadii.lgPlus)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShapeIcon(
          icon: Icons.insights_rounded,
          shape: ExpressiveShape.softBurst,
          size: 44,
          fill: AppColors.high,
          foreground: AppColors.muted,
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    ),
  );
}

/// A small expressive shape that keys a series in a legend.
class ShapeMarker extends StatelessWidget {
  const ShapeMarker({required this.color, this.shape = ExpressiveShape.circle, this.size = 14, super.key});
  final Color color;
  final ExpressiveShape shape;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: ShapeDecoration(color: color, shape: ExpressiveShapeBorder(shape)),
    ),
  );
}

/// Legend key: shape marker before its label.
class LegendSwatch extends StatelessWidget {
  const LegendSwatch({required this.color, required this.label, this.shape = ExpressiveShape.circle, super.key});
  final Color color;
  final String label;
  final ExpressiveShape shape;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ShapeMarker(color: color, shape: shape),
      const SizedBox(width: AppSpace.sm),
      Flexible(
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: tabular, color: AppColors.ink),
        ),
      ),
    ],
  );
}

/// Legend key of a dashed reference line (e.g. the daily average).
class DashKey extends StatelessWidget {
  const DashKey(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final dash = Container(width: 5, height: 2, color: AppColors.muted.withValues(alpha: 0.6));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dash,
        const SizedBox(width: 4),
        dash,
        const SizedBox(width: AppSpace.sm),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: tabular, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

/// Pill-ended horizontal bar on a pill track; [fraction] in 0..1.
class MeterBar extends StatelessWidget {
  const MeterBar({required this.fraction, required this.color, this.height = 10, super.key});
  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: ChartColors.track, borderRadius: BorderRadius.circular(AppRadii.full)),
    alignment: AlignmentDirectional.centerStart,
    child: FractionallySizedBox(
      widthFactor: fraction.clamp(0.0, 1.0),
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.full)),
      ),
    ),
  );
}

typedef BarRow = ({String label, double value, String text});

/// Horizontal ranked bars with an optional leading badge.
/// [colors] gives each row its own role colour (e.g. per status); otherwise
/// every bar is brand. [leading] puts a shaped badge before each row.
class RankedBars extends StatelessWidget {
  const RankedBars({required this.rows, this.colors, this.leading, super.key});

  final List<BarRow> rows;
  final List<Color>? colors;
  final List<Widget>? leading;

  @override
  Widget build(BuildContext context) {
    final max = rows.fold<double>(0, (a, r) => r.value > a ? r.value : a);
    return Column(
      children: [
        for (final (i, row) in rows.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null && i < leading!.length) ...[leading![i], const SizedBox(width: AppSpace.md)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(row.label, style: context.text.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        row.text,
                        style: context.text.bodySmall?.copyWith(fontFeatures: tabular, color: AppColors.muted),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      MeterBar(
                        fraction: max <= 0 ? 0 : row.value / max,
                        color: colors != null && i < colors!.length ? colors![i] : ChartColors.main,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
