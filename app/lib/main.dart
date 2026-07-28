import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'core/design_system/theme.dart';
import 'features/auth/auth_screen.dart';

// Entry point
void main() {
  runApp(const ActivoTradeApp());
}

// root widget
class ActivoTradeApp extends StatelessWidget {
  const ActivoTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      title: 'ActivoTrade',
      theme: ActivoTradeTheme.lightTheme,
      darkTheme: ActivoTradeTheme.darkTheme,
      themeMode:
          ThemeMode.system, // Automatically follows OS Light/Dark setting
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthScreen(),
    );
  }
}

