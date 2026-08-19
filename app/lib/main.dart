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
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Firebase once here; if it fails, log it and keep the app running.
  try {
    // Web has no config file, so Firebase options must be passed in by hand.
    await Firebase.initializeApp(
      options: kIsWeb ? DefaultFirebaseOptions.web : null,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init failed; push notifications unavailable: $e');
    }
  }

  setupServiceLocator();
  // Start push notifications here so they work from any screen.
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
