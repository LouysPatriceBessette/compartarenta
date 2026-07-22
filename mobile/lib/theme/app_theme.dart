import 'package:flutter/material.dart';

/// Bojairũ brand palette shared with the public website.
abstract final class AppBrandColors {
  static const Color sand = Color(0xFFFFF7ED);
  static const Color peach = Color(0xFFFED7AA);
  static const Color rust = Color(0xFF9A3412);
  static const Color clay = Color(0xFF7C2D12);
  static const Color stone = Color(0xFF78716C);
  static const Color tornadoBase = Color(0xFFFDBA74);
  static const Color tornadoYellow = Color(0xFFFCD34D);

  /// Darker tornado tone used for AA contrast on light backgrounds.
  static const Color tornadoAmber = Color(0xFFB45309);

  static const Color tornadoOrange = Color(0xFFFB923C);
  static const Color vehicleBlue = Color(0xFF0284C7);
  static const Color housingOrange = Color(0xFFEA580C);
  static const Color moneyGreen = Color(0xFF16A34A);
  static const Color calendarViolet = Color(0xFF7C3AED);

  /// Elevated light card surface. Palette [peach] — stronger than [sand]
  /// so hub tiles and other Cards remain visible against the scaffold.
  static const Color lightCard = peach;

  /// Website dark `--bg`: 32% clay mixed with #2A211C.
  static const Color darkBackground = Color(0xFF442519);

  /// Elevated dark card surface. Palette [clay] — stronger than [darkBackground]
  /// so hub tiles and other Cards remain visible.
  static const Color darkCard = clay;
}

ColorScheme _lightColorScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppBrandColors.rust,
    brightness: Brightness.light,
  );
  return base.copyWith(
    primary: AppBrandColors.rust,
    onPrimary: AppBrandColors.sand,
    primaryContainer: AppBrandColors.peach,
    onPrimaryContainer: AppBrandColors.clay,
    secondary: AppBrandColors.tornadoAmber,
    onSecondary: AppBrandColors.sand,
    secondaryContainer: AppBrandColors.tornadoYellow,
    onSecondaryContainer: AppBrandColors.clay,
    tertiary: AppBrandColors.calendarViolet,
    onTertiary: AppBrandColors.sand,
    tertiaryContainer: AppBrandColors.peach,
    onTertiaryContainer: AppBrandColors.clay,
    error: AppBrandColors.rust,
    onError: AppBrandColors.sand,
    errorContainer: AppBrandColors.peach,
    onErrorContainer: AppBrandColors.clay,
    surface: AppBrandColors.sand,
    onSurface: AppBrandColors.clay,
    onSurfaceVariant: AppBrandColors.stone,
    outline: AppBrandColors.stone,
    outlineVariant: AppBrandColors.peach,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppBrandColors.lightCard,
    surfaceContainer: AppBrandColors.sand,
    surfaceContainerHigh: const Color(0xFFFFEAD7),
    surfaceContainerHighest: AppBrandColors.peach,
  );
}

ColorScheme _darkColorScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppBrandColors.tornadoBase,
    brightness: Brightness.dark,
  );
  return base.copyWith(
    primary: AppBrandColors.tornadoBase,
    onPrimary: AppBrandColors.clay,
    primaryContainer: AppBrandColors.clay,
    onPrimaryContainer: AppBrandColors.sand,
    secondary: AppBrandColors.tornadoYellow,
    onSecondary: AppBrandColors.clay,
    secondaryContainer: AppBrandColors.rust,
    onSecondaryContainer: AppBrandColors.sand,
    tertiary: AppBrandColors.peach,
    onTertiary: AppBrandColors.clay,
    tertiaryContainer: AppBrandColors.calendarViolet,
    onTertiaryContainer: AppBrandColors.sand,
    error: AppBrandColors.tornadoOrange,
    onError: AppBrandColors.clay,
    errorContainer: AppBrandColors.rust,
    onErrorContainer: AppBrandColors.sand,
    surface: AppBrandColors.darkBackground,
    onSurface: AppBrandColors.sand,
    onSurfaceVariant: AppBrandColors.peach,
    outline: AppBrandColors.peach,
    outlineVariant: AppBrandColors.clay,
    surfaceContainerLowest: const Color(0xFF2A211C),
    surfaceContainerLow: AppBrandColors.darkCard,
    surfaceContainer: AppBrandColors.darkCard,
    surfaceContainerHigh: AppBrandColors.rust,
    surfaceContainerHighest: AppBrandColors.tornadoAmber,
  );
}

ThemeData _buildTheme(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: scheme.primary.withValues(alpha: 0.12),
      iconTheme: IconThemeData(color: scheme.onSurface),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: scheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      circularTrackColor: scheme.primaryContainer,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
    ),
  );
}

/// Application-wide Bojairũ light theme.
ThemeData buildAppTheme() => _buildTheme(_lightColorScheme());

/// Application-wide Bojairũ dark theme matching the public website.
ThemeData buildAppDarkTheme() => _buildTheme(_darkColorScheme());
