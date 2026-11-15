import 'package:flutter/material.dart';

part 'palette_schemes.dart';

/// Colour palettes offered in "Tema & tampilan". Navy Scitech matches the
/// Scitech brand mark and is the default with a hand-tuned slate-navy scheme;
/// Zamrud keeps the hand-tuned green scheme; the others come from their seed
/// via [DynamicSchemeVariant.vibrant].
enum SchemeKey {
  navy('Navy Scitech', Color(0xFF0F2C59)),
  cobalt('Kobalt', Color(0xFF2E5BD0)),
  emerald('Zamrud', Color(0xFF1E6B47)),
  coral('Koral', Color(0xFFD9382C)),
  amber('Amber', Color(0xFFF5B700)),
  violet('Violet', Color(0xFF6B3FA0)),
  magenta('Magenta', Color(0xFFD02670));

  const SchemeKey(this.label, this.seed);
  final String label;

  /// The colour the palette is named after; the light hero uses it as is.
  final Color seed;
}

enum ContrastLevel { standard, medium, high }

/// Item categories that have their own shape and tint.
enum CategoryTone { camera, drone, audio, projector, tools }

/// Material scheme for [key]. [seedOverride] (wallpaper colour) replaces the
/// palette seed; contrast above standard always uses the generator.
ColorScheme schemeFor(
  SchemeKey key,
  Brightness brightness, {
  ContrastLevel contrast = ContrastLevel.standard,
  Color? seedOverride,
}) {
  final level = switch (contrast) {
    ContrastLevel.standard => 0.0,
    ContrastLevel.medium => .5,
    ContrastLevel.high => 1.0,
  };
  if (seedOverride == null && contrast == ContrastLevel.standard) {
    if (key == SchemeKey.navy) return brightness == Brightness.light ? _navyLight : _navyDark();
    if (key == SchemeKey.emerald) return brightness == Brightness.light ? _leafLight : _leafDark();
  }
  final scheme = ColorScheme.fromSeed(
    seedColor: seedOverride ?? key.seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    contrastLevel: level,
  );
  // Navy keeps the logo colour on buttons in light mode.
  if (seedOverride == null && key == SchemeKey.navy && brightness == Brightness.light && level == 0) {
    return scheme.copyWith(primary: key.seed, onPrimary: Colors.white);
  }
  return scheme;
}

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
}

/// Resolved colour roles for one palette, brightness and contrast: the
/// Material [scheme] plus hero and status roles that do not change meaning
/// when the palette changes.
class AppPalette {
  AppPalette._({required this.key, required this.scheme, required this.seed})
    : dark = scheme.brightness == Brightness.dark {
    final light = schemeFor(key, Brightness.light, seedOverride: seed == key.seed ? null : seed);
    if (dark) {
      hero = scheme.primaryContainer;
      onHero = scheme.onPrimaryContainer;
      heroSoft = Color.lerp(hero, onHero, .1)!;
    } else {
      hero = key == SchemeKey.navy && seed == key.seed
          ? _scitechNavy
          : (key == SchemeKey.emerald && seed == key.seed ? _forest : seed);
      onHero = contrastRatio(Colors.white, hero) >= 3 ? Colors.white : light.onPrimaryContainer;
      heroSoft = Color.lerp(hero, onHero, .12)!;
    }
    brandInk = light.primary;
  }

  factory AppPalette.resolve({
    required SchemeKey scheme,
    required bool dark,
    ContrastLevel contrast = ContrastLevel.standard,
    Color? seedOverride,
  }) => AppPalette._(
    key: scheme,
    seed: seedOverride ?? scheme.seed,
    scheme: schemeFor(
      scheme,
      dark ? Brightness.dark : Brightness.light,
      contrast: contrast,
      seedOverride: seedOverride,
    ),
  );

  final SchemeKey key;
  final ColorScheme scheme;
  final Color seed;
  final bool dark;

  /// Bold block colour of the one hero card per screen, and the content on
  /// it. [heroSoft] tints shapes on the hero; [brandInk] is the light
  /// scheme's primary, for text on white overlays even in dark mode.
  late final Color hero, onHero, heroSoft, brandInk;

  Color get brand => scheme.primary;
  Color get onBrand => scheme.onPrimary;
  Color get primary => scheme.primary;
  Color get fixed => scheme.primaryContainer;
  Color get onFixed => scheme.onPrimaryContainer;

  /// Secondary container: tonal buttons, nav pill, selected chips.
  Color get secondary => scheme.secondaryContainer;
  Color get onSecondary => scheme.onSecondaryContainer;
  Color get surface => scheme.surface;
  Color get card => scheme.surfaceContainerLowest;
  Color get low => scheme.surfaceContainerLow;
  Color get container => scheme.surfaceContainer;
  Color get high => scheme.surfaceContainerHigh;
  Color get highest => scheme.surfaceContainerHighest;
  Color get onSurface => scheme.onSurface;
  Color get onSurfaceVariant => scheme.onSurfaceVariant;
  Color get outline => scheme.outline;
  Color get outlineVariant => scheme.outlineVariant;
  Color get heroShape => onHero;
  Color get onHeroShape => hero;
  bool get heroIsDark => hero.computeLuminance() < .4;

  /// Warning status (deadlines, work waiting on someone); AgroLens amber.
  Color get deadline => dark ? const Color(0xFFFFB95C) : const Color(0xFF8B4F00);
  Color get deadlineContainer => dark ? const Color(0xFF5A3A0C) : const Color(0xFFFFE2B8);
  Color get onDeadlineContainer => dark ? const Color(0xFFFFDDB0) : const Color(0xFF6B3D00);
  Color get deadlineTrack => dark ? const Color(0xFF8A5A1A) : const Color(0xFFF2C27A);

  /// Keyboard focus ring.
  Color get accent => dark ? const Color(0xFFFFB95C) : const Color(0xFFE8681F);
  Color get error => scheme.error;
  Color get errorContainer => dark ? const Color(0xFF6E1F1A) : const Color(0xFFFFDAD5);
  Color get onErrorContainer => dark ? const Color(0xFFFFDAD5) : const Color(0xFF8C1D18);

  /// Healthy / done status.
  Color get ok => dark ? const Color(0xFF8BD7A6) : const Color(0xFF1F7A4D);
  Color get okContainer => dark ? const Color(0xFF1C4A2C) : const Color(0xFFCDEFD3);
  Color get onOkContainer => dark ? const Color(0xFFB4EDC0) : const Color(0xFF0B5129);
  Color get disabled => scheme.onSurface.withValues(alpha: .12);
  Color get onDisabled => scheme.onSurface.withValues(alpha: .38);

  (Color, Color) category(CategoryTone tone) => switch (tone) {
    CategoryTone.camera => (scheme.primaryContainer, scheme.onPrimaryContainer),
    CategoryTone.drone => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    CategoryTone.audio => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    CategoryTone.projector => (deadlineContainer, onDeadlineContainer),
    CategoryTone.tools => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
  };

  /// True when both palettes would paint identically.
  bool sameAs(AppPalette other) => key == other.key && scheme == other.scheme && hero == other.hero;

  /// The palette the app currently renders with. [AppColors] reads from it, so
  /// it is replaced (and the tree rebuilt) whenever appearance changes.
  static AppPalette current = AppPalette.resolve(scheme: SchemeKey.navy, dark: false);
}

/// Shorthand for the current palette's roles. Runtime getters: never inside
/// `const` expressions.
abstract final class AppColors {
  static AppPalette get _p => AppPalette.current;
  static bool get dark => _p.dark;
  static Color get brand => _p.brand;
  static Color get onBrand => _p.onBrand;
  static Color get primary => _p.primary;
  static Color get fixed => _p.fixed;
  static Color get onFixed => _p.onFixed;
  static Color get secondary => _p.secondary;
  static Color get onSecondary => _p.onSecondary;

  /// Page background. Cards and list items sit on it in [card].
  static Color get page => _p.surface;
  static Color get card => _p.card;
  static Color get low => _p.low;
  static Color get container => _p.container;
  static Color get high => _p.high;
  static Color get highest => _p.highest;
  static Color get ink => _p.onSurface;
  static Color get muted => _p.onSurfaceVariant;
  static Color get outline => _p.outline;
  static Color get line => _p.outlineVariant;
  static Color get hero => _p.hero;
  static Color get onHero => _p.onHero;
  static Color get heroShape => _p.heroShape;
  static Color get onHeroShape => _p.onHeroShape;
  static Color get heroSoft => _p.heroSoft;
  static Color get brandInk => _p.brandInk;

  /// Fill for small shapes on the hero; null keeps the category tint.
  static Color? get heroTile => null;
  static bool get heroIsDark => _p.heroIsDark;
  static Color get deadline => _p.deadline;
  static Color get deadlineContainer => _p.deadlineContainer;
  static Color get onDeadlineContainer => _p.onDeadlineContainer;
  static Color get deadlineTrack => _p.deadlineTrack;
  static Color get accent => _p.accent;
  static Color get error => _p.error;
  static Color get errorContainer => _p.errorContainer;
  static Color get onErrorContainer => _p.onErrorContainer;
  static Color get ok => _p.ok;
  static Color get okContainer => _p.okContainer;
  static Color get onOkContainer => _p.onOkContainer;
  static Color get disabled => _p.disabled;
  static Color get onDisabled => _p.onDisabled;
  static (Color, Color) category(CategoryTone tone) => _p.category(tone);
}
