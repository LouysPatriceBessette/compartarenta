import 'package:compartarenta/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses the Bojairũ website roles', () {
    final theme = buildAppTheme();
    final scheme = theme.colorScheme;

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppBrandColors.sand);
    expect(scheme.primary, AppBrandColors.rust);
    expect(scheme.onPrimary, AppBrandColors.sand);
    expect(scheme.primaryContainer, AppBrandColors.peach);
    expect(scheme.onPrimaryContainer, AppBrandColors.clay);
    expect(scheme.onSurface, AppBrandColors.clay);
    expect(scheme.onSurfaceVariant, AppBrandColors.stone);
    expect(scheme.outlineVariant, AppBrandColors.peach);
    expect(theme.cardTheme.color, AppBrandColors.lightCard);
  });

  test('dark theme uses the Bojairũ website roles', () {
    final theme = buildAppDarkTheme();
    final scheme = theme.colorScheme;

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppBrandColors.darkBackground);
    expect(scheme.primary, AppBrandColors.tornadoBase);
    expect(scheme.onPrimary, AppBrandColors.clay);
    expect(scheme.primaryContainer, AppBrandColors.clay);
    expect(scheme.onPrimaryContainer, AppBrandColors.sand);
    expect(scheme.onSurface, AppBrandColors.sand);
    expect(scheme.onSurfaceVariant, AppBrandColors.peach);
    expect(scheme.outlineVariant, AppBrandColors.clay);
    expect(theme.cardTheme.color, AppBrandColors.darkCard);
    expect(AppBrandColors.darkCard, AppBrandColors.clay);
    expect(AppBrandColors.darkCard, isNot(AppBrandColors.darkBackground));
  });
}
