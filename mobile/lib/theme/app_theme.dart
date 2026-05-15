import 'package:flutter/material.dart';

/// Brand palette derived from the piggy-bank / savings illustration (sky blues,
/// deep blue accents, warm sand, ink outlines).
abstract final class AppBrandColors {
  /// Deep blue — primary actions, AppBar contrast, emphasis.
  static const Color primaryBlue = Color(0xFF2E5984);

  /// Soft sky — containers, primary backgrounds.
  static const Color primaryBlueLight = Color(0xFFAED6F1);

  /// Mid sky blue — secondary / accents (piggy tone).
  static const Color accentSky = Color(0xFF7FB3D5);

  /// Warm sand — supportive surfaces / secondary containers.
  static const Color warmSand = Color(0xFFE5C39E);

  /// Near-black — body text, icons on light surfaces.
  static const Color ink = Color(0xFF1A1A1B);

  /// Subtle AppBar / surface tint toward the accent.
  static const Color surfaceTint = accentSky;
}

ColorScheme _lightColorScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppBrandColors.primaryBlue,
    brightness: Brightness.light,
  );
  return base.copyWith(
    primary: AppBrandColors.primaryBlue,
    onPrimary: Colors.white,
    primaryContainer: AppBrandColors.primaryBlueLight,
    onPrimaryContainer: AppBrandColors.primaryBlue,
    secondary: AppBrandColors.accentSky,
    onSecondary: AppBrandColors.ink,
    secondaryContainer: AppBrandColors.warmSand,
    onSecondaryContainer: AppBrandColors.ink,
    tertiary: AppBrandColors.accentSky,
    onTertiary: AppBrandColors.ink,
    surface: Colors.white,
    onSurface: AppBrandColors.ink,
    onSurfaceVariant: AppBrandColors.primaryBlue,
    surfaceContainerLow: const Color(0xFFF5FAFD),
    surfaceContainer: const Color(0xFFE8F2FA),
    surfaceContainerHigh: const Color(0xFFDDEAF4),
    surfaceContainerHighest: const Color(0xFFD0E2EF),
  );
}

/// Application-wide light theme (dark mode not configured yet).
ThemeData buildAppTheme() {
  final scheme = _lightColorScheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: AppBrandColors.surfaceTint.withValues(alpha: 0.22),
      iconTheme: IconThemeData(color: scheme.onSurface),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      surfaceTintColor: AppBrandColors.surfaceTint.withValues(alpha: 0.12),
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
