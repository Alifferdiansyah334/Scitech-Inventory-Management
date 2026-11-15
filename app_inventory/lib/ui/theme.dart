import 'package:flutter/material.dart';
import 'button_feedback.dart';
import 'morph.dart';
import 'springs.dart';
import 'tokens.dart';

/// Material 3 Expressive theme for one resolved [AppPalette]. Buttons morph
/// their corners on a spring while pressed; [still] (reduced motion) makes
/// shape changes instant.
ThemeData buildAppTheme(AppPalette p, {bool still = false}) {
  final morph = still ? Duration.zero : fastSpatialCurve.duration;
  final scheme = p.scheme.copyWith(surfaceTint: Colors.transparent);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.sans,
    scaffoldBackgroundColor: p.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkSparkle.splashFactory,
  );
  // ThemeData.textTheme carries no sizes until Theme.of localizes it; the
  // component themes below need them, so merge the English-like geometry in.
  final t = base.typography.englishLike
      .merge(base.textTheme)
      .apply(bodyColor: p.onSurface, displayColor: p.onSurface, fontFamily: AppFonts.sans);
  final text = t.copyWith(
    displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5),
    displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.2),
    displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1),
    headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.8),
    headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.6),
    headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.4),
    titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -.2),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: t.bodyLarge?.copyWith(height: 1.55),
    bodyMedium: t.bodyMedium?.copyWith(height: 1.5),
    labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
  );
  // AgroLens button geometry: 52 tall, 22 side padding, 15 px label.
  final buttonText = text.labelLarge!.copyWith(fontSize: 15);
  final focusRing = WidgetStateProperty.resolveWith<BorderSide?>(
    (s) => s.contains(WidgetState.focused) ? BorderSide(color: p.accent, width: 3) : null,
  );
  OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.lg),
    borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
  );
  return base.copyWith(
    textTheme: text,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SpringPageTransitionsBuilder(),
        TargetPlatform.iOS: SpringPageTransitionsBuilder(),
        TargetPlatform.linux: SpringPageTransitionsBuilder(),
        TargetPlatform.macOS: SpringPageTransitionsBuilder(),
        TargetPlatform.windows: SpringPageTransitionsBuilder(),
        TargetPlatform.fuchsia: SpringPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      foregroundColor: p.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: p.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        textStyle: buttonText,
        disabledBackgroundColor: p.disabled,
        disabledForegroundColor: p.onDisabled,
        animationDuration: morph,
      ).copyWith(side: focusRing, shape: morphShape(), foregroundBuilder: expressiveButtonForeground),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        elevation: 0,
        backgroundColor: p.card,
        foregroundColor: p.primary,
        textStyle: buttonText,
        animationDuration: morph,
      ).copyWith(side: focusRing, shape: morphShape(), foregroundBuilder: expressiveButtonForeground),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        foregroundColor: p.primary,
        disabledForegroundColor: p.onDisabled,
        side: BorderSide(color: p.outlineVariant),
        textStyle: buttonText,
        animationDuration: morph,
      ).copyWith(shape: morphShape(), foregroundBuilder: expressiveButtonForeground),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        minimumSize: const Size(48, 48),
        textStyle: buttonText,
        animationDuration: morph,
      ).copyWith(side: focusRing, shape: morphShape(), foregroundBuilder: expressiveButtonForeground),
    ),
    iconButtonTheme: IconButtonThemeData(
      style:
          IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: p.onSurfaceVariant,
            animationDuration: morph,
          ).copyWith(
            side: focusRing,
            shape: morphShape(pressed: 14, selected: 16),
            foregroundBuilder: expressiveButtonForeground,
          ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.fixed,
      foregroundColor: p.onFixed,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 1,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lgPlus)),
      extendedTextStyle: buttonText,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.high,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: TextStyle(color: p.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (s) => TextStyle(
          color: s.contains(WidgetState.error)
              ? p.error
              : s.contains(WidgetState.focused)
              ? p.brand
              : p.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      hintStyle: TextStyle(color: p.onSurfaceVariant),
      prefixIconColor: p.onSurfaceVariant,
      suffixIconColor: p.onSurfaceVariant,
      border: field(p.outline, 0),
      enabledBorder: field(p.outline, 0),
      disabledBorder: field(p.outlineVariant, 0),
      focusedBorder: field(p.brand, 2),
      errorBorder: field(p.error, 1.5),
      focusedErrorBorder: field(p.error, 2),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: p.secondary,
      checkmarkColor: p.onSecondary,
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected) ? BorderSide.none : BorderSide(color: p.outlineVariant),
      ),
      shape: const ChipMorphBorder(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onSecondary : p.onSurfaceVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.low,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.secondary,
      indicatorShape: const StadiumBorder(),
      height: 80,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? p.onSurface : p.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.onSecondary : p.onSurfaceVariant),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.container,
      indicatorColor: p.secondary,
      indicatorShape: const StadiumBorder(),
      selectedIconTheme: IconThemeData(color: p.onSecondary),
      unselectedIconTheme: IconThemeData(color: p.onSurfaceVariant),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.low,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.outline,
      modalBarrierColor: Colors.black.withValues(alpha: p.dark ? .55 : .32),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.high,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xxl)),
      titleTextStyle: text.headlineSmall?.copyWith(color: p.onSurface),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.onSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.surface),
      actionTextColor: p.fixed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xs)),
      side: BorderSide(color: p.outline, width: 2),
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Icon(Icons.check_rounded, size: 16, color: p.brand) : null,
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 16,
      activeTrackColor: p.brand,
      inactiveTrackColor: p.secondary,
      thumbColor: p.brand,
      thumbShape: const HandleThumbShape(),
      trackShape: const GappedSliderTrackShape(),
      trackGap: 6,
      thumbSize: const WidgetStatePropertyAll(Size(4, 44)),
      valueIndicatorColor: p.onSurface,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brand, linearTrackColor: p.secondary),
    dividerTheme: DividerThemeData(color: p.outlineVariant, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: p.onSurfaceVariant,
      tileColor: p.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: text.titleMedium?.copyWith(color: p.onSurface),
      subtitleTextStyle: text.bodyMedium?.copyWith(color: p.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.listInner)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.onSurface, borderRadius: BorderRadius.circular(AppRadii.sm)),
      textStyle: TextStyle(color: p.surface, fontSize: 12),
    ),
  );
}

/// Hero roles read by the expressive controls: a bold block colour, the
/// content on it, a soft tint for shapes layered on the hero, and the brand
/// ink for text on white overlays.
class HeroColors {
  const HeroColors({required this.hero, required this.onHero, required this.heroSoft, required this.ink});
  final Color hero, onHero, heroSoft, ink;
}

extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  HeroColors get palette =>
      HeroColors(hero: AppColors.hero, onHero: AppColors.onHero, heroSoft: AppColors.heroSoft, ink: AppColors.brandInk);
}
