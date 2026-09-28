import 'dart:async';

import 'package:activotrade_app/core/routing/deep_link_controller.dart';
import 'package:activotrade_app/features/notifications/data/services/local_notifications_service.dart';
import 'package:activotrade_app/features/notifications/data/services/notification_tap_handler.dart';
import 'package:activotrade_app/features/notifications/data/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockLocalNotificationsService extends Mock
    implements LocalNotificationsService {}

PushMessage _message(Map<String, String> data) =>
    PushMessage(title: 'Order filled', body: '500 AAPL', data: data);

void main() {
  late MockPushNotificationService pushService;
  late MockLocalNotificationsService localNotifications;
  late StreamController<PushMessage> openedApp;
  late StreamController<Map<String, String>> foregroundTaps;
  late DeepLinkController deepLinks;
  late NotificationTapHandler handler;

  setUp(() {
    pushService = MockPushNotificationService();
    localNotifications = MockLocalNotificationsService();
    openedApp = StreamController<PushMessage>.broadcast();
    foregroundTaps = StreamController<Map<String, String>>.broadcast();
    deepLinks = DeepLinkController();

    when(
      () => pushService.onNotificationTap,
    ).thenAnswer((_) => openedApp.stream);
    when(
      () => localNotifications.onTap,
    ).thenAnswer((_) => foregroundTaps.stream);
    when(() => pushService.initialMessage()).thenAnswer((_) async => null);

    handler = NotificationTapHandler(
      pushService: pushService,
      localNotifications: localNotifications,
      deepLinks: deepLinks,
    );
  });

  tearDown(() async {
    await handler.stop();
    await openedApp.close();
    await foregroundTaps.close();
    deepLinks.dispose();
  });

  group('cold boot', () {
    test('parks the route the launching notification asked for', () async {
      when(() => pushService.initialMessage()).thenAnswer(
        (_) async =>
            _message(<String, String>{'route': '/dashboard', 'id': '77'}),
      );

      await handler.start();

      expect(deepLinks.consume(), '/dashboard?id=77');
    });

    test('parks nothing on an ordinary launch', () async {
      await handler.start();

      expect(deepLinks.hasPending, isFalse);
    });

    test(
      'does not hang start-up when the platform never answers',
      () async {
        // A stuck platform channel should only cost the timeout, never block start-up.
        when(
          () => pushService.initialMessage(),
        ).thenAnswer((_) => Completer<PushMessage?>().future);

        await handler.start();

        expect(deepLinks.hasPending, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('background tap', () {
    test('parks the route from onMessageOpenedApp', () async {
      await handler.start();

      openedApp.add(
        _message(<String, String>{'route': '/dashboard', 'id': '9'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(deepLinks.consume(), '/dashboard?id=9');
    });

    test('puts the id in the path for a route that declares one', () async {
      // The demo path end to end: /alerts is declared as /alerts/:id, so the
      // id becomes a segment rather than a query parameter.
      await handler.start();

      openedApp.add(
        _message(<String, String>{'route': '/alerts', 'id': 'alert_987'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(deepLinks.consume(), '/alerts/alert_987');
    });

    test('parks nothing when a path id would reshape the route', () async {
      await handler.start();

      openedApp.add(
        _message(<String, String>{'route': '/alerts', 'id': '../login'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(deepLinks.hasPending, isFalse);
    });
  });

  group('foreground tap', () {
    test('parks the route from our own banner', () async {
      await handler.start();

      foregroundTaps.add(<String, String>{'route': '/dashboard'});
      await Future<void>.delayed(Duration.zero);

      expect(deepLinks.consume(), '/dashboard');
    });
  });

  group('payloads that are not links', () {
    test('a notification with no route parks nothing', () async {
      await handler.start();

      // The common case. Opening the app is all this notification was for.
      openedApp.add(_message(<String, String>{'campaign': 'weekly-digest'}));
      await Future<void>.delayed(Duration.zero);

      expect(deepLinks.hasPending, isFalse);
    });

    test('a route outside the whitelist parks nothing', () async {
      await handler.start();

      openedApp.add(_message(<String, String>{'route': '/login'}));
      await Future<void>.delayed(Duration.zero);

      expect(deepLinks.hasPending, isFalse);
    });
  });

  group('start()', () {
    test('is safe to call twice and does not double-subscribe', () async {
      await handler.start();
      await handler.start();

      // A second start() must not subscribe twice, or every tap fires twice.
      verify(() => pushService.onNotificationTap).called(1);
      verify(() => localNotifications.onTap).called(1);
    });

    test('swallows a failure rather than breaking start-up', () async {
      when(() => pushService.onNotificationTap).thenThrow(Exception('no fcm'));

      // start() must never throw, or it can crash the whole app.
      await expectLater(handler.start(), completes);
    });
  });
}
