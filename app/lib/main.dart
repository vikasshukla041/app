import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/app_auth_cubit.dart';
import 'core/auth/app_auth_state.dart';
import 'core/design_system/theme.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/foreground_push_handler.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/locked_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialised once here rather than lazily inside a service: Firebase is a
  // process-wide dependency, and starting it mid-flow hides a missing
  // google-services.json behind whatever feature happened to trigger it.
  // A failure is logged and the app still runs — only push is unavailable.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init failed; push notifications unavailable: $e');
    }
  }

  setupServiceLocator();
  // Started push notification here so, can land on any screen
  unawaited(getIt<ForegroundPushHandler>().start());

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
              //
              AppAuthInitial() => const _SplashScreen(),
              AppUnauthenticated() => const AuthScreen(),
            };
          },
        ),
      ),
    );
  }
}

// neutral holding screen shown while saved session is being restored.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
