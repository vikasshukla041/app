import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/app_auth_cubit.dart';
import 'core/design_system/theme.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'features/auth/auth_cubit.dart';
import 'features/notifications/data/services/foreground_push_handler.dart';
import 'features/notifications/data/services/notification_tap_handler.dart';
import 'features/notifications/widgets/notification_session_listener.dart';
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

  // Awaited, unlike the handler above: a notification that launched the app
  // has to reach DeepLinkController before the router runs its first redirect.
  await getIt<NotificationTapHandler>().start();

  unawaited(getIt<AppAuthCubit>().checkSession());

  runApp(ActivoTradeApp(router: getIt<AppRouter>()));
}

/// Composition root: provides GetIt singletons, theme, localization and router.
class ActivoTradeApp extends StatelessWidget {
  const ActivoTradeApp({super.key, required this.router});

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        // .value, not create: the router already holds this singleton and
        // would otherwise be listening to a cubit this provider later closes.
        BlocProvider<AppAuthCubit>.value(value: getIt<AppAuthCubit>()),
        BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
      ],
      child: MaterialApp.router(
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ActivoTradeTheme.lightTheme,
        darkTheme: ActivoTradeTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router.config,
        // MaterialApp.router has no `home`, so the session listener wraps every
        // route from here. Dropping it stops the push token being re-claimed on
        // sign-in, which is silent — no error, just the wrong user's alerts.
        builder: (BuildContext context, Widget? child) =>
            NotificationSessionListener(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
