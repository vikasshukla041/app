import 'package:flutter/material.dart';

/// Font sizes and weights used across the app. No font family yet — that comes later.
abstract final class AppTypography {
  /// List rows emphasize their title without changing ordinary body text.
  static TextStyle get listTileTitle =>
      textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600);

  /// Only the roles the design defines; anything else keeps Material's default.
  static const TextTheme textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.48,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.30,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.16,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.22,
    ),
  );
}

/// Money and counts. Material has no slot for these because they use a second font.
@immutable
class AppFigureText extends ThemeExtension<AppFigureText> {
  const AppFigureText({
    required this.large,
    required this.medium,
    required this.small,
  });

  /// The one figure a screen is built around, such as a total.
  final TextStyle large;

  /// A single row's own amount.
  final TextStyle medium;

  /// Account numbers, timestamps, and anything else secondary.
  final TextStyle small;

  // No font family yet either; these three get one once it's added to the app.
  static const AppFigureText standard = AppFigureText(
    large: TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.64,
    ),
    medium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    ),
    small: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
    ),
  );

  @override
  AppFigureText copyWith({
    TextStyle? large,
    TextStyle? medium,
    TextStyle? small,
  }) {
    return AppFigureText(
      large: large ?? this.large,
      medium: medium ?? this.medium,
      small: small ?? this.small,
    );
  }

  @override
  AppFigureText lerp(AppFigureText? other, double t) {
    if (other == null) {
      return this;
    }
    return AppFigureText(
      large: TextStyle.lerp(large, other.large, t)!,
      medium: TextStyle.lerp(medium, other.medium, t)!,
      small: TextStyle.lerp(small, other.small, t)!,
    );
  }
}
