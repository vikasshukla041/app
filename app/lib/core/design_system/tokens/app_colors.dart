import 'package:flutter/material.dart';

/// Every literal colour in the app
abstract final class AppColors {
  static const Color white = Color(0xFFFFFFFF);

  // neutral every background, border and text colour.
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  /// The page sits one step below a card so the two never blend together.
  static const Color canvas = Color(0xFFFAFBFD);

  /// Holds white text at 6.5:1, which the brighter [brandBright] cannot.
  static const Color brand = Color(0xFF006491);

  /// The design's cyan: safe behind dark text, so it leads the dark theme.
  static const Color brandBright = Color(0xFF03B1FC);

  static const Color brandContainer = Color(0xFFE0F4FF);
  static const Color brandDark = Color(0xFF00405E);

  // Gains, settled trades
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald900 = Color(0xFF064E3B);

  // Pending and clearing states
  static const Color amber100 = Color(0xFFFFEFC9);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber900 = Color(0xFF564500);

  // error
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color errorLightContainer = Color(0xFFFFDAD6);
  static const Color onErrorLightContainer = Color(0xFF93000A);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);

  // Accents that only tell one dashboard tile from the next.
  static const Color blue600 = Color(0xFF2563EB);
  static const Color purple600 = Color(0xFF9333EA);
  static const Color orange600 = Color(0xFFEA580C);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color purple400 = Color(0xFFC084FC);
  static const Color orange400 = Color(0xFFFB923C);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color indigo400 = Color(0xFF818CF8);
}
