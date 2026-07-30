import 'package:flutter/material.dart';

import 'core/design_system/theme.dart';
import 'features/auth/auth_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ActivoTradeApp());
}

/// Composition root: theme, localization delegates and the first screen.
/// Feature state is provided per-screen, not globally.
class ActivoTradeApp extends StatelessWidget {
  const ActivoTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ActivoTradeTheme.lightTheme,
      darkTheme: ActivoTradeTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthScreen(),
    );
  }
}
