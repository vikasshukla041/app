import 'dart:async';

import 'package:activotrade_app/core/auth/app_auth_cubit.dart';
import 'package:activotrade_app/core/auth/app_auth_state.dart';
import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/features/notifications/data/services/foreground_push_handler.dart';
import 'package:activotrade_app/features/notifications/data/services/local_notifications_service.dart';
import 'package:activotrade_app/features/notifications/data/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockLocalNotificationsService extends Mock
    implements LocalNotificationsService {}

class MockAppAuthCubit extends Mock implements AppAuthCubit {}

void main() {
  late MockPushNotificationService pushService;
  late MockLocalNotificationsService localNotifications;
  late MockAppAuthCubit appAuthCubit;
  late StreamController<PushMessage> messages;
  late ForegroundPushHandler handler;

  const User demoUser = User(
    id: 'user_demo_123',
    username: 'demo',
    fullname: 'Demo Investor',
  );

  void stubSession(AppAuthState state) {
    when(() => appAuthCubit.state).thenReturn(state);
  }

  setUp(() {
    pushService = MockPushNotificationService();
    localNotifications = MockLocalNotificationsService();
    appAuthCubit = MockAppAuthCubit();
    messages = StreamController<PushMessage>.broadcast();

    when(
      () => pushService.onForegroundMessage,
    ).thenAnswer((_) => messages.stream);
    when(() => localNotifications.init()).thenAnswer((_) async {});
    when(
      () => localNotifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    // Signed in unless a test says otherwise.
    stubSession(const AppAuthenticated(demoUser));

    handler = ForegroundPushHandler(
      pushService: pushService,
      localNotifications: localNotifications,
      appAuthCubit: appAuthCubit,
    );
  });

  tearDown(() async {
    await handler.stop();
    await messages.close();
  });

  test('shows a banner for a foreground message', () async {
    await handler.start();

    messages.add(const PushMessage(title: 'Market Alert', body: 'EUR/USD up'));
    await Future<void>.delayed(Duration.zero);

    verify(
      () => localNotifications.show(
        title: 'Market Alert',
        body: 'EUR/USD up',
        payload: any(named: 'payload'),
      ),
    ).called(1);
  });

  test('forwards the data payload so the banner stays tappable', () async {
    await handler.start();

    // Without this a tap on a banner this app drew could not open a route,
    // while a tap on a system notification could — same push, two behaviours.
    messages.add(
      const PushMessage(
        title: 'Order filled',
        body: '500 AAPL',
        data: <String, String>{'route': '/alerts', 'id': 'alert_987'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    verify(
      () => localNotifications.show(
        title: 'Order filled',
        body: '500 AAPL',
        payload: <String, String>{'route': '/alerts', 'id': 'alert_987'},
      ),
    ).called(1);
  });

  test('initialises the plugin exactly once across repeated starts', () async {
    await handler.start();
    await handler.start();

    verify(() => localNotifications.init()).called(1);
  });

  test('concurrent starts subscribe only once', () async {
    // Without the synchronous guard both callers see a null subscription —
    // the field is only assigned after `init()` completes — and every banner
    // would be drawn twice.
    await Future.wait<void>(<Future<void>>[handler.start(), handler.start()]);

    messages.add(const PushMessage(title: 'Order filled', body: '500 AAPL'));
    await Future<void>.delayed(Duration.zero);

    verify(
      () => localNotifications.show(
        title: 'Order filled',
        body: '500 AAPL',
        payload: any(named: 'payload'),
      ),
    ).called(1);
  });

  test('swallows an init failure instead of escaping to the zone', () async {
    when(() => localNotifications.init()).thenThrow(Exception('no plugin'));

    // start() is launched unawaited from main(); a throw here would become an
    // unhandled zone error rather than a failed push feature.
    await expectLater(handler.start(), completes);

    messages.add(const PushMessage(title: 'x', body: 'y'));
    await Future<void>.delayed(Duration.zero);

    verifyNever(
      () => localNotifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test('stop cancels the subscription', () async {
    await handler.start();
    await handler.stop();

    messages.add(const PushMessage(title: 'x', body: 'y'));
    await Future<void>.delayed(Duration.zero);

    verifyNever(
      () => localNotifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });

  group('session gate', () {
    // The device stays subscribed to FCM after sign-out — there is no
    // de-registration endpoint yet — so pushes keep arriving for an account
    // nobody is signed into. Showing them would leak that account's activity
    // to whoever is holding the phone.
    Future<void> expectDropped(AppAuthState state) async {
      stubSession(state);
      await handler.start();

      messages.add(
        const PushMessage(title: 'Order filled', body: '500 AAPL'),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => localNotifications.show(
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    }

    test('drops a push when the user is signed out', () async {
      await expectDropped(const AppUnauthenticated());
    });

    test('drops a push while the session is locked', () async {
      // The app is on screen behind the unlock prompt; a banner there would
      // defeat the lock it is sitting on.
      await expectDropped(const AppAuthLocked(demoUser));
    });

    test('drops a push during the biometric opt-in', () async {
      // Tokens are saved by this point, but the user has not finished signing
      // in and the router still has them on a pre-auth screen.
      await expectDropped(const AppAuthPendingBiometricOptIn(demoUser));
    });

    test('drops a push before the session check has finished', () async {
      await expectDropped(const AppAuthInitial());
    });

    test('shows a push again once the user signs back in', () async {
      stubSession(const AppUnauthenticated());
      await handler.start();

      messages.add(const PushMessage(title: 'Dropped', body: 'while out'));
      await Future<void>.delayed(Duration.zero);

      // Same subscription, new session: the gate is read per message, so
      // signing in must not require restarting the handler.
      stubSession(const AppAuthenticated(demoUser));
      messages.add(const PushMessage(title: 'Market Alert', body: 'EUR/USD up'));
      await Future<void>.delayed(Duration.zero);

      verify(
        () => localNotifications.show(
          title: 'Market Alert',
          body: 'EUR/USD up',
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verifyNever(
        () => localNotifications.show(
          title: 'Dropped',
          body: 'while out',
          payload: any(named: 'payload'),
        ),
      );
    });
  });
}
