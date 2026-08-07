import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/app_auth_cubit.dart';
import 'core/auth/app_auth_state.dart';
import 'core/design_system/theme.dart';
import 'core/di/service_locator.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/locked_screen.dart';
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
        BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
      ],
      child: MaterialApp(
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ActivoTradeTheme.lightTheme,
        darkTheme: ActivoTradeTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocBuilder<AppAuthCubit, AppAuthState>(
          builder: (context, state) {
            return switch (state) {
              AppAuthenticated() => const DashboardScreen(),
              AppAuthLocked(:final user) => LockedScreen(user: user),
              // checkSession() reads secure storage asynchronously. Mapping
              // the pre-answer state to AuthScreen flashes the login form on
              // every launch before the lock screen replaces it.
              AppAuthInitial() => const _SplashScreen(),
              AppUnauthenticated() => const AuthScreen(),
            };
          },
        ),
      ),
    );
  }
}

/// Neutral holding screen shown while the saved session is being restored.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
