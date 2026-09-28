// The single source of truth for the app's look; every value comes from tokens/.
import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_typography.dart';

class ActivoTradeTheme {
  ActivoTradeTheme._();

  /// Taller than Material's default, so buttons are easy to tap.
  static const double _minButtonHeight = 50;

  static ThemeData get lightTheme => _build(_lightScheme);
  static ThemeData get darkTheme => _build(_darkScheme);

  static ThemeData _build(ColorScheme colors) {
    final bool isLight = colors.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      textTheme: AppTypography.textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      // elevation: 0 gives a thin border instead of a heavy shadow.
      cardTheme: CardThemeData(
        elevation: 0,
        // Gaps come from AppSpacing, so Material's own 4px margin only blurs them.
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      // Hairline. Material's default 16 would push list rows apart.
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTypography.listTileTitle.copyWith(
          color: colors.onSurface,
        ),
        subtitleTextStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xs,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, _minButtonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, _minButtonHeight),
        ),
      ),
      // Was the only button type without a theme, so it ignored the height.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, _minButtonHeight),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppFigureText.standard,
        isLight ? AppSemanticColors.light : AppSemanticColors.dark,
        isLight ? AppCategoryColors.light : AppCategoryColors.dark,
      ],
    );
  }

  // Colors are set by hand here; fromSeed can't produce this exact palette.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.brandContainer,
    onPrimaryContainer: AppColors.brand,
    secondary: AppColors.slate600,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.slate100,
    onSecondaryContainer: AppColors.slate800,
    tertiary: AppColors.emerald700,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.emerald50,
    onTertiaryContainer: AppColors.emerald900,
    error: AppColors.errorLight,
    onError: AppColors.white,
    errorContainer: AppColors.errorLightContainer,
    onErrorContainer: AppColors.onErrorLightContainer,
    surface: AppColors.canvas,
    onSurface: AppColors.slate900,
    onSurfaceVariant: AppColors.slate500,
    outline: AppColors.slate300,
    outlineVariant: AppColors.slate200,
    // Cards live one step above the page, so they are white while the page is not.
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.white,
    surfaceContainer: AppColors.slate50,
    surfaceContainerHigh: AppColors.slate100,
    surfaceContainerHighest: AppColors.slate200,
    inverseSurface: AppColors.slate900,
    onInverseSurface: AppColors.slate50,
    inversePrimary: AppColors.brandBright,
  );

  /// The design ships no dark palette, so this inverts the same ramp.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brandBright,
    onPrimary: AppColors.slate900,
    primaryContainer: AppColors.brandDark,
    onPrimaryContainer: AppColors.brandContainer,
    secondary: AppColors.slate400,
    onSecondary: AppColors.slate900,
    secondaryContainer: AppColors.slate700,
    onSecondaryContainer: AppColors.slate200,
    tertiary: AppColors.emerald400,
    onTertiary: AppColors.slate900,
    tertiaryContainer: AppColors.emerald900,
    onTertiaryContainer: AppColors.emerald50,
    error: AppColors.errorDark,
    onError: AppColors.onErrorDark,
    errorContainer: AppColors.onErrorLightContainer,
    onErrorContainer: AppColors.errorLightContainer,
    surface: AppColors.slate900,
    onSurface: AppColors.slate50,
    onSurfaceVariant: AppColors.slate400,
    outline: AppColors.slate600,
    outlineVariant: AppColors.slate700,
    surfaceContainerLowest: AppColors.slate900,
    surfaceContainerLow: AppColors.slate800,
    surfaceContainer: AppColors.slate800,
    surfaceContainerHigh: AppColors.slate700,
    surfaceContainerHighest: AppColors.slate700,
    inverseSurface: AppColors.slate50,
    onInverseSurface: AppColors.slate900,
    inversePrimary: AppColors.brand,
  );
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.warningContainer,
    required this.onWarningContainer,
    required this.warning,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.positive,
  });

  final Color warningContainer;
  final Color onWarningContainer;

  /// The warning colour on its own, for a dot or a stroke with no container.
  final Color warning;

  final Color successContainer;
  final Color onSuccessContainer;

  /// M3 has no "success" role; used for positive financial figures (gains).
  final Color positive;

  static const AppSemanticColors light = AppSemanticColors(
    warningContainer: AppColors.amber100,
    onWarningContainer: AppColors.amber900,
    warning: AppColors.amber700,
    successContainer: AppColors.emerald50,
    onSuccessContainer: AppColors.emerald900,
    positive: AppColors.emerald700,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    warningContainer: AppColors.amber900,
    onWarningContainer: AppColors.amber100,
    warning: AppColors.amber400,
    // Swapped, not reused: light values would look pale on a dark surface.
    successContainer: AppColors.emerald900,
    onSuccessContainer: AppColors.emerald50,
    positive: AppColors.emerald400,
  );

  @override
  AppSemanticColors copyWith({
    Color? warningContainer,
    Color? onWarningContainer,
    Color? warning,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? positive,
  }) {
    return AppSemanticColors(
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      warning: warning ?? this.warning,
      positive: positive ?? this.positive,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) {
      return this;
    }
    // Each ?? keeps the colour we already show if a blend ever comes back empty.
    return AppSemanticColors(
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t) ??
          onWarningContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t) ??
          onSuccessContainer,
      positive: Color.lerp(positive, other.positive, t) ?? positive,
    );
  }
}

/// Accents that carry no meaning of their own; they only tell tiles apart.
@immutable
class AppCategoryColors extends ThemeExtension<AppCategoryColors> {
  const AppCategoryColors({required this.accents});

  final List<Color> accents;

  // These colors all stay clearly visible on a light background.
  static const AppCategoryColors light = AppCategoryColors(
    accents: <Color>[
      AppColors.blue600,
      AppColors.purple600,
      AppColors.orange600,
      AppColors.teal600,
      AppColors.indigo600,
    ],
  );

  // Lighter shades so these colors stay visible on a dark background.
  static const AppCategoryColors dark = AppCategoryColors(
    accents: <Color>[
      AppColors.blue400,
      AppColors.purple400,
      AppColors.orange400,
      AppColors.teal400,
      AppColors.indigo400,
    ],
  );

  @override
  AppCategoryColors copyWith({List<Color>? accents}) {
    return AppCategoryColors(accents: accents ?? this.accents);
  }

  @override
  AppCategoryColors lerp(AppCategoryColors? other, double t) {
    if (other == null || other.accents.length != accents.length) {
      return this;
    }
    return AppCategoryColors(
      accents: <Color>[
        // Falls back to the accent already on screen if a blend comes back empty.
        for (int i = 0; i < accents.length; i++)
          Color.lerp(accents[i], other.accents[i], t) ?? accents[i],
      ],
    );
  }
}
