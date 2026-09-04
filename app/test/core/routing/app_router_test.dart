import 'package:activotrade_app/core/auth/app_auth_cubit.dart';
import 'package:activotrade_app/core/auth/app_auth_state.dart';
import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/core/routing/app_router.dart';
import 'package:activotrade_app/core/routing/deep_link_controller.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/features/alerts/alert_detail_screen.dart';
import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:activotrade_app/features/auth/auth_screen.dart';
import 'package:activotrade_app/features/auth/biometric_onboarding_screen.dart';
import 'package:activotrade_app/features/auth/data/services/biometric_service.dart';
import 'package:activotrade_app/features/auth/locked_screen.dart';
import 'package:activotrade_app/features/dashboard/dashboard_screen.dart';
import 'package:activotrade_app/features/splash/splash_screen.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBiometricService extends Mock implements BiometricService {}

/// Sets AppAuthCubit's state directly so tests skip storage and network.
class _FakeAppAuthCubit extends AppAuthCubit {
  _FakeAppAuthCubit(SecureStorageService storage)
    : super(storageService: storage);

  void setState(AppAuthState state) => emit(state);
}

void main() {
  const User user = User(id: '1', username: 'demo', fullname: 'Demo User');

  late MockSecureStorageService storage;
  late MockBiometricService biometrics;
  late _FakeAppAuthCubit authCubit;
  late DeepLinkController deepLinks;
  late AppRouter router;

  setUp(() {
    storage = MockSecureStorageService();
    biometrics = MockBiometricService();
    // Stub this so LockedScreen's auto-unlock does not hit the real plugin.
    when(
      () => biometrics.authenticate(reason: any(named: 'reason')),
    ).thenAnswer((_) async => BiometricResult.cancelled);

    authCubit = _FakeAppAuthCubit(storage);
    deepLinks = DeepLinkController();
    router = AppRouter(authCubit: authCubit, deepLinks: deepLinks);
  });

  tearDown(() async {
    router.dispose();
    deepLinks.dispose();
    await authCubit.close();
  });

  /// Mounts the router with AuthCubit provided, since some screens read it.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppAuthCubit>.value(value: authCubit),
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(
              storageService: storage,
              biometricService: biometrics,
            ),
          ),
        ],
        child: MaterialApp.router(
          // DashboardScreen reads AppSemanticColors off the theme; the
          // default ThemeData does not have it.
          theme: ActivoTradeTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router.config,
        ),
      ),
    );
    // Not pumpAndSettle(): the initial state renders SplashScreen, whose
    // CircularProgressIndicator animates forever and would time it out.
    await tester.pump();
  }

  group('auth gate', () {
    testWidgets('holds on the splash until the session is resolved', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      // Show the splash, not the login form, until the session is known.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('sends an unauthenticated user to the login screen', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      authCubit.setState(const AppUnauthenticated());
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('sends a locked session to the unlock screen', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      authCubit.setState(const AppAuthLocked(user));
      await tester.pumpAndSettle();

      expect(find.byType(LockedScreen), findsOneWidget);
    });

    testWidgets('sends a pending opt-in to the biometric onboarding screen', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      authCubit.setState(const AppAuthPendingBiometricOptIn(user));
      await tester.pumpAndSettle();

      expect(find.byType(BiometricOnboardingScreen), findsOneWidget);
    });

    testWidgets('lands an authenticated user on the dashboard', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('moves the user off the login screen once authenticated', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      authCubit.setState(const AppUnauthenticated());
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);

      // Nothing else moves them: the login screen performs no navigation.
      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
    });

    testWidgets('throws a signed-out user off the dashboard', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      // The 401 path: AuthInterceptor forces a logout from anywhere.
      authCubit.setState(const AppUnauthenticated());
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });
  });

  // The first cases assert the parking machinery — a tap has to survive a
  // cold boot and a login before it is honoured. The last two assert what the
  // user actually sees: the alert the notification named, and nothing at all
  // if they are signed out.
  group('deep links', () {
    testWidgets('is honoured as soon as the user is authenticated', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      deepLinks.push('/dashboard?id=123');
      await tester.pumpAndSettle();

      expect(deepLinks.hasPending, isFalse);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('is held while the session is still unresolved', (
      WidgetTester tester,
    ) async {
      // The cold-boot case: the tap is parked before checkSession() answers.
      deepLinks.push('/dashboard?id=123');
      await pumpApp(tester);

      // Still unresolved, so the link must wait rather than be dropped.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(deepLinks.hasPending, isTrue);

      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      expect(deepLinks.hasPending, isFalse);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('survives a login before it is honoured', (
      WidgetTester tester,
    ) async {
      deepLinks.push('/dashboard?id=123');
      await pumpApp(tester);

      // Signed out: the gate wins and the link must still be waiting after.
      authCubit.setState(const AppUnauthenticated());
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(deepLinks.hasPending, isTrue);

      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      expect(deepLinks.hasPending, isFalse);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('is consumed once, so a later refresh does not reopen it', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      deepLinks.push('/dashboard?id=123');
      await tester.pumpAndSettle();
      expect(deepLinks.hasPending, isFalse);

      // A later refresh, like a token rotation, must not resurrect the link.
      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      expect(deepLinks.hasPending, isFalse);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('a newer tap replaces an unconsumed older one', (
      WidgetTester tester,
    ) async {
      deepLinks.push('/dashboard?id=111');
      deepLinks.push('/dashboard?id=222');

      // Read before mounting: only the second tap should have survived.
      expect(deepLinks.consume(), '/dashboard?id=222');
      expect(deepLinks.hasPending, isFalse);

      await pumpApp(tester);
    });

    testWidgets('opens the alert a notification named, not the dashboard', (
      WidgetTester tester,
    ) async {
      // The whole point of the feature: a tap lands on the alert itself.
      await pumpApp(tester);
      authCubit.setState(const AppAuthenticated(user));
      await tester.pumpAndSettle();

      deepLinks.push('/alerts/alert_987?title=Order+filled');
      await tester.pumpAndSettle();

      expect(find.byType(AlertDetailScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // The id comes from the path, the title from the query — the split
      // DeepLinkParser produces.
      final AlertDetailScreen screen = tester.widget<AlertDetailScreen>(
        find.byType(AlertDetailScreen),
      );
      expect(screen.alertId, 'alert_987');
      expect(screen.title, 'Order filled');
    });

    testWidgets('a signed-out user never reaches the alert', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      authCubit.setState(const AppUnauthenticated());
      await tester.pumpAndSettle();

      deepLinks.push('/alerts/alert_987');
      await tester.pumpAndSettle();

      // The gate wins; the link waits for a session rather than leaking it.
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(AlertDetailScreen), findsNothing);
      expect(deepLinks.hasPending, isTrue);
    });
  });
}
