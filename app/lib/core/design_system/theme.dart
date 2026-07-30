import 'package:flutter/material.dart';

/// The single source of truth for the app's look.
///
/// Light and dark themes share one private builder so they can never
/// drift apart — change a value once, both modes update.
class ActivoTradeTheme {
  ActivoTradeTheme._();

  static const Color _seedColor = Color(0xFF2B7FFF);

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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        isLight ? AppSemanticColors.light : AppSemanticColors.dark,
      ],
    );
  }
}

/// Semantic colors Material 3 does not provide out of the box.
///
/// M3 has error roles but no "warning" role, so we define our own token
/// pair the M3 way (container + on-container, light + dark tonal pairs).
/// Usage: `Theme.of(context).extension<AppSemanticColors>()!`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color warningContainer;
  final Color onWarningContainer;

  static const AppSemanticColors light = AppSemanticColors(
    warningContainer: Color(0xFFFFEFC9),
    onWarningContainer: Color(0xFF564500),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    warningContainer: Color(0xFF564500),
    onWarningContainer: Color(0xFFFFEFC9),
  );

  @override
  AppSemanticColors copyWith({
    Color? warningContainer,
    Color? onWarningContainer,
  }) {
    return AppSemanticColors(
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppSemanticColors(
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
    );
  }
}
