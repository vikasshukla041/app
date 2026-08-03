import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/app_auth_cubit.dart';
import 'core/auth/app_auth_state.dart';
import 'core/design_system/theme.dart';
import 'core/di/service_locator.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const ActivoTradeApp());
}

/// Composition root: provides GetIt singletons, theme, localization and auth gateway.
class ActivoTradeApp extends StatelessWidget {
  const ActivoTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppAuthCubit>(
          create: (_) => getIt<AppAuthCubit>()..checkSession(),
        ),
        BlocProvider<AuthCubit>(
          create: (_) => getIt<AuthCubit>()..checkBiometricAvailability(),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ActivoTradeTheme.lightTheme,
        darkTheme: ActivoTradeTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocBuilder<AppAuthCubit, AppAuthState>(
          builder: (context, state) {
            if (state is AppAuthenticated) {
              return const DashboardScreen();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}

