import 'package:activotrade_app/core/auth/app_auth_cubit.dart';
import 'package:activotrade_app/core/auth/app_auth_state.dart';
import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/features/notifications/notification_cubit.dart';
import 'package:activotrade_app/features/notifications/widgets/notification_resume_listener.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockNotificationCubit extends Mock implements NotificationCubit {}

/// Lets a test put the session in any state it needs.
class _FakeAppAuthCubit extends AppAuthCubit {
  _FakeAppAuthCubit(AppAuthState initial)
    : super(storageService: MockSecureStorageService()) {
    emit(initial);
  }
}

void main() {
  late MockNotificationCubit notifications;

  setUp(() {
    notifications = MockNotificationCubit();
    when(
      () => notifications.refreshAfterResume(),
    ).thenAnswer((_) async => NotificationResumeOutcome.enabled);
  });

  Future<void> pumpListener(WidgetTester tester, AppAuthState session) async {
    final AppAuthCubit authCubit = _FakeAppAuthCubit(session);
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      BlocProvider<AppAuthCubit>.value(
        value: authCubit,
        child: MaterialApp(
          theme: ActivoTradeTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NotificationResumeListener(
              notifications: notifications,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> leaveAndComeBack(WidgetTester tester) async {
    // Flutter checks each step, so the app walks out and back one state at a time.
    for (final AppLifecycleState step in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(step);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('checks the permission when a signed-in user comes back', (
    WidgetTester tester,
  ) async {
    await pumpListener(
      tester,
      const AppAuthenticated(User(id: '1', username: 'alex', fullname: 'Alex')),
    );

    await leaveAndComeBack(tester);

    verify(() => notifications.refreshAfterResume()).called(1);
  });

  testWidgets('does nothing on the login screen', (WidgetTester tester) async {
    // The regression: registering with no session failed and showed a warning.
    await pumpListener(tester, const AppUnauthenticated());

    await leaveAndComeBack(tester);

    verifyNever(() => notifications.refreshAfterResume());
    expect(find.byType(SnackBar), findsNothing);
  });
}
