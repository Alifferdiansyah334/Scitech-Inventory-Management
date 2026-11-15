part of '../app_update_page.dart';

extension _UpdateViews on _AppUpdatePageState {
  /// 38% of the screen, and always tall enough for the title at the
  /// current text size.
  double headerHeight() {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final fit = MediaQuery.paddingOf(context).top + 124 + 85 * scale;
    return math.max((MediaQuery.sizeOf(context).height * .38).clamp(220.0, 360.0), fit);
  }

  /// Shape header: the hero colour with a turning cookie and the update
  /// mark, the page name, and a dark translucent back disc.
  Widget header() {
    final pal = context.palette;
    return SizedBox(
      height: headerHeight(),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
        child: ColoredBox(
          color: pal.hero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -60,
                top: -30,
                child: IgnorePointer(
                  child: Ambient(
                    period: const Duration(seconds: 28),
                    builder: (context, spin, _) => SizedBox.square(
                      dimension: 300,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: pal.heroSoft,
                          shape: ExpressiveShapeBorder(ExpressiveShape.cookie12, rotation: spin * 2 * math.pi),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Kembali',
                            onPressed: updates.downloading ? null : () => Navigator.maybePop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0x66000000),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          ExcludeSemantics(
                            child: Bob(
                              turn: .08,
                              child: ShapeIcon(
                                icon: Icons.system_update_rounded,
                                shape: ExpressiveShape.sunny8,
                                size: 56,
                                fill: pal.onHero,
                                foreground: pal.hero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appName,
                              style: context.text.labelLarge?.copyWith(color: pal.onHero.withValues(alpha: .85)),
                            ),
                            Semantics(
                              header: true,
                              child: WordReveal(
                                'Pembaruan aplikasi',
                                style: context.text.headlineMedium?.copyWith(height: 1.12, color: pal.onHero),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Verdict card: status pill, title and installed version on the left; a
  /// wavy ring with the download progress or the status icon on the right.
  Widget statusCard() {
    final s = status();
    final colors = toneColors(s.tone);
    final ring = updates.downloading
        ? updates.progress / 100
        : updates.available && !updates.downloaded
        ? 0.0
        : updates.checking
        ? .3
        : 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: context.colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: context.colors.outlineVariant.withValues(alpha: .6)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(s.pill, tone: s.tone),
                    const SizedBox(height: 12),
                    Text(s.title, style: context.text.headlineSmall?.copyWith(height: 1.15)),
                    const SizedBox(height: 4),
                    Text(s.message, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text(
                      'Terpasang: SIMS ${updates.installedVersion} · build ${updates.installedBuild}',
                      style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              WavyRingProgress(
                value: ring,
                size: 96,
                color: colors.fg,
                semanticsLabel: updates.downloading ? 'Unduhan ${updates.progress}%' : s.pill,
                child: updates.downloading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountUp(updates.progress, style: context.text.titleLarge?.copyWith(height: 1)),
                          Text('%', style: context.text.labelSmall),
                        ],
                      )
                    : ShapeIcon(
                        icon: s.icon,
                        shape: toneShape(s.tone),
                        size: 52,
                        fill: colors.bg,
                        foreground: colors.fg,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tonal note card with a shape badge (error, permission).
  Widget note(String text, Tone tone, {Widget? action}) {
    final colors = toneColors(tone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShapeIcon(
                icon: toneIcon(tone) ?? Icons.info_outline_rounded,
                shape: toneShape(tone),
                size: 36,
                fill: colors.fg,
                foreground: colors.bg,
                iconScale: .5,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: context.text.bodyMedium?.copyWith(color: colors.fg)),
                      ?action,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom bar of the result screen: outlined square check on the left,
  /// the step that moves the update forward on the right.
  Widget actionBar() {
    final busy = updates.checking || updates.downloading;
    final Widget primary;
    if (!updates.available) {
      primary = FilledButton.icon(
        onPressed: busy ? null : updates.check,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Periksa pembaruan'),
      );
    } else if (updates.downloading) {
      primary = FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.downloading_rounded),
        label: Text('Mengunduh ${updates.progress}%'),
      );
    } else if (updates.isWeb || updates.downloaded) {
      primary = FilledButton.icon(
        onPressed: install,
        icon: const Icon(Icons.system_update_rounded),
        label: Text(updates.isWeb ? 'Gunakan versi terbaru' : 'Pasang pembaruan'),
      );
    } else {
      primary = FilledButton.icon(
        onPressed: updates.download,
        icon: const Icon(Icons.download_rounded),
        label: const Text('Unduh pembaruan'),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant.withValues(alpha: .5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (updates.available) ...[
                IconButton.outlined(
                  tooltip: 'Periksa pembaruan',
                  onPressed: busy ? null : updates.check,
                  style: IconButton.styleFrom(fixedSize: const Size.square(52)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 52), child: primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
