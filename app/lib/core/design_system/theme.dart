// The single source of truth for app's look
import 'package:flutter/material.dart';

class ActivoTradeTheme {
  ActivoTradeTheme._();

  static const Color _seedColor = Color(0xFF2B7FFF);
  static const double _minButtonHeight = 50;

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        isLight ? AppSemanticColors.light : AppSemanticColors.dark,
        AppCategoryColors.standard,
      ],
    );
  }
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.warningContainer,
    required this.onWarningContainer,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.positive,
  });

  final Color warningContainer;
  final Color onWarningContainer;
  final Color successContainer;
  final Color onSuccessContainer;

  /// M3 has no "success" role; used for positive financial figures (gains).
  final Color positive;

  static const AppSemanticColors light = AppSemanticColors(
    warningContainer: Color(0xFFFFEFC9),
    onWarningContainer: Color(0xFF564500),
    successContainer: Color(0xFFD1FAE5),
    onSuccessContainer: Color(0xFF064E3B),
    positive: Color(0xFF10B981),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    warningContainer: Color(0xFF564500),
    onWarningContainer: Color(0xFFFFEFC9),
    // Swapped like the warning pair above. Reusing the light values here puts
    // a pale-green bar on a dark surface, the one element on screen that
    // ignores the theme.
    successContainer: Color(0xFF064E3B),
    onSuccessContainer: Color(0xFFD1FAE5),
    positive: Color(0xFF34D399),
  );

  @override
  AppSemanticColors copyWith({
    Color? warningContainer,
    Color? onWarningContainer,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? positive,
  }) {
    return AppSemanticColors(
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
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
    return AppSemanticColors(
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      positive: Color.lerp(positive, other.positive, t)!,
    );
  }
}

/// Fixed, decorative accent colors for categorical icons (e.g. dashboard
/// quick-link tiles). Not brightness- or role-sensitive — purely visual
/// differentiation between items, so a single set covers light and dark.
@immutable
class AppCategoryColors extends ThemeExtension<AppCategoryColors> {
  const AppCategoryColors({required this.accents});

  final List<Color> accents;

  static const AppCategoryColors standard = AppCategoryColors(
    accents: <Color>[
      Color(0xFF2563EB), // blue
      Color(0xFF9333EA), // purple
      Color(0xFFEA580C), // orange
      Color(0xFF0D9488), // teal
      Color(0xFF4F46E5), // indigo
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
        for (int i = 0; i < accents.length; i++)
          Color.lerp(accents[i], other.accents[i], t)!,
      ],
    );
  }
}
