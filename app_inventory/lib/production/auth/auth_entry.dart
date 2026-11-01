import 'package:flutter/material.dart';
import '../../ui/components.dart';
import '../../ui/springs.dart';
import '../../ui/tokens.dart';

/// Login entry: navy brand area with the label-card hero and a white sheet
/// holding [children]. Side by side from 900 px wide.
class AuthEntry extends StatelessWidget {
  const AuthEntry({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final form = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
      final wide =
          constraints.maxWidth >= 900 ||
          (constraints.maxWidth >= 600 &&
              constraints.maxWidth > constraints.maxHeight);
      if (wide) {
        return Row(
          children: [
            Expanded(
              child: ColoredBox(
                color: AppColors.navy,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthBrand(),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) => Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: AuthHero(
                                  height: box.maxHeight.clamp(0.0, 300.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.surface,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      final pad = MediaQuery.paddingOf(context);
      final heroH = (constraints.maxHeight * .28).clamp(150.0, 230.0);
      final topH = pad.top + 20 + 44 + 12 + heroH + 16;
      final minSheetH = (constraints.maxHeight - topH).clamp(
        0.0,
        double.infinity,
      );
      return ColoredBox(
        color: AppColors.navy,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, pad.top + 20, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthBrand(),
                    const SizedBox(height: 12),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AuthHero(height: heroH),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(minHeight: minSheetH),
                padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + pad.bottom),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadii.sheet),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: form,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// White-tinted logo with the app name.
class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: Image.asset('assets/images/Logo.png', width: 44, height: 44),
      ),
      const SizedBox(width: 12),
      const Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventaris Scitech',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Peminjaman barang internal',
              style: TextStyle(fontSize: 14, color: AppColors.navyMuted),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Three overlapping, rotated asset label cards on a navy2 disc. Generic
/// category labels only: no invented item codes or counts.
class AuthHero extends StatelessWidget {
  const AuthHero({required this.height, super.key});
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = height;
          final card = (w * .56).clamp(150.0, 220.0);
          final cards = [
            (left: w * .30, top: h * .02, angle: -.07, label: 'Proyektor'),
            (left: w * .03, top: h * .31, angle: .06, label: 'Kamera'),
            (left: w * .38, top: h * .58, angle: -.04, label: 'Perkakas'),
          ];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -w * .14,
                top: h * .04,
                child: Container(
                  width: h * 1.05,
                  height: h * 1.05,
                  decoration: const BoxDecoration(
                    color: AppColors.navy2,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              for (final (i, c) in cards.indexed)
                Positioned(
                  left: c.left,
                  top: c.top,
                  child: SpringReveal(
                    index: i,
                    child: AssetLabelCard(
                      title: 'Label aset',
                      subtitle: c.label,
                      angle: c.angle,
                      width: card,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// Two-option segmented switch; the navy thumb slides with the snappy spring.
class AuthSegmented extends StatelessWidget {
  const AuthSegmented({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = reducedMotion(context)
        ? Duration.zero
        : snappyCurve.duration;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: index == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: duration,
              curve: snappyCurve,
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, label) in labels.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onChanged == null || i == index
                          ? null
                          : () => onChanged!(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontFamily: AppFonts.sans,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: i == index ? Colors.white : AppColors.muted,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
