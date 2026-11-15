part of '../controls.dart';

class _SegmentBadge<T> extends StatelessWidget {
  const _SegmentBadge({
    required this.seg,
    required this.isSel,
    required this.s,
    required this.p,
    required this.t,
    required this.badgeSize,
    required this.badgeBg,
    required this.badgeFg,
    required this.bg,
  });

  final ExpressiveSegment<T> seg;
  final bool isSel;
  final double s;
  final double p;
  final double t;
  final double badgeSize;
  final Color badgeBg;
  final Color badgeFg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return SizedBox.square(
      dimension: badgeSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: badgeBg,
                shape: ExpressiveShapeBorder(
                  seg.shape,
                  morphTo: ExpressiveShape.cookie12,
                  morph: (s * .55 + p * .4).clamp(0, 1.2),
                  rotation: (s * .85 + p * .45) * math.pi / 4,
                ),
              ),
              child: Center(
                child: seg.monogram != null
                    ? Text(
                        seg.monogram!,
                        style: context.text.labelLarge?.copyWith(
                          color: badgeFg,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      )
                    : Icon(
                        seg.icon ?? (isSel ? Icons.check_rounded : Icons.circle_outlined),
                        size: badgeSize * .48,
                        color: badgeFg,
                      ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Transform.scale(
              scale: (.4 + .6 * t).clamp(0.0, 1.3),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isSel ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: bg, width: 2),
                ),
                child: isSel ? Icon(Icons.check_rounded, size: 10, color: scheme.onSecondaryContainer) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
