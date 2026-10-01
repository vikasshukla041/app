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
// import 'features/notifications/widgets/notification_resume_listener.dart';
import 'features/notifications/widgets/notification_resume_listener.dart';
import 'features/notifications/widgets/notification_session_listener.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start firebase once
  try {
    await Firebase.initializeApp(
      options: kIsWeb ? DefaultFirebaseOptions.web : null,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase init failed; push notifications unavailable: $e');
    }
  }

  setupServiceLocator();

  // Started push notification here so, can land on any screen
  unawaited(getIt<ForegroundPushHandler>().start());

  // awaited, notification has reached DeepLinkController before router run
  await getIt<NotificationTapHandler>().start();

  unawaited(getIt<AppAuthCubit>().checkSession());

  runApp(ActivoTradeApp(router: getIt<AppRouter>()));
}

/// Composition root: provides GetIt singletons, theme, localization and auth gateway.
class ActivoTradeApp extends StatelessWidget {
  const ActivoTradeApp({super.key, required this.router});

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
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
        builder: (BuildContext context, Widget? child) =>
            NotificationSessionListener(
              child: NotificationResumeListener(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
      ),
    );
  }
}
