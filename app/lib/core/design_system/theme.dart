// The single source of truth for the app's look.
// No fontFamily yet, so type uses the platform default.
import 'package:flutter/material.dart';

import 'tokens/app_radius.dart';
import 'tokens/app_spacing.dart';

class ActivoTradeTheme {
  ActivoTradeTheme._();

  static const Color _seedColor = Color(0xFF2B7FFF);
  static const double _cardElevation = 2;

  /// Taller than Material's default, so buttons are easy to tap.
  static const double _minButtonHeight = 50;

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      textTheme: _textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: _cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      // Hairline. Material's default 16 would push list rows apart.
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
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
        isLight ? AppSemanticColors.light : AppSemanticColors.dark,
        isLight ? AppCategoryColors.light : AppCategoryColors.dark,
      ],
    );
  }

  /// Only the roles that are bold everywhere. The rest differ by screen, so
  /// design has to decide before they move here.
  static const TextTheme _textTheme = TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontWeight: FontWeight.bold),
    labelMedium: TextStyle(fontWeight: FontWeight.bold),
  );
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
    // Emerald 700. The lighter green failed WCAG AA at 2.47:1; this is 5.35:1.
    positive: Color(0xFF047857),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    warningContainer: Color(0xFF564500),
    onWarningContainer: Color(0xFFFFEFC9),
    // Swapped, not reused: light values would look pale on a dark surface.
    successContainer: Color(0xFF064E3B),
    onSuccessContainer: Color(0xFFD1FAE5),
    // Emerald 400, already 8.91:1 on dark.
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

/// Accent colors that tell the dashboard quick-link icons apart.
/// They mean nothing on their own, so they do not come from the seed.
@immutable
class AppCategoryColors extends ThemeExtension<AppCategoryColors> {
  const AppCategoryColors({required this.accents});

  final List<Color> accents;

  /// 3.47:1 to 6.13:1 on the light surface — all above the 3:1 an icon needs.
  static const AppCategoryColors light = AppCategoryColors(
    accents: <Color>[
      Color(0xFF2563EB), // blue 600
      Color(0xFF9333EA), // purple 600
      Color(0xFFEA580C), // orange 600
      Color(0xFF0D9488), // teal 600
      Color(0xFF4F46E5), // indigo 600
    ],
  );

  /// Lighter shades. Indigo above was 2.72:1 on dark and vanished; these
  /// are 5.74:1 and up.
  static const AppCategoryColors dark = AppCategoryColors(
    accents: <Color>[
      Color(0xFF60A5FA), // blue 400
      Color(0xFFC084FC), // purple 400
      Color(0xFFFB923C), // orange 400
      Color(0xFF2DD4BF), // teal 400
      Color(0xFF818CF8), // indigo 400
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
