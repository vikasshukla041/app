import 'dart:async';

import 'package:activotrade_app/core/notifications/foreground_push_handler.dart';
import 'package:activotrade_app/core/notifications/local_notifications_service.dart';
import 'package:activotrade_app/core/notifications/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockLocalNotificationsService extends Mock
    implements LocalNotificationsService {}

void main() {
  late MockPushNotificationService pushService;
  late MockLocalNotificationsService localNotifications;
  late StreamController<PushMessage> messages;
  late ForegroundPushHandler handler;

  setUp(() {
    pushService = MockPushNotificationService();
    localNotifications = MockLocalNotificationsService();
    messages = StreamController<PushMessage>.broadcast();

    when(
      () => pushService.onForegroundMessage,
    ).thenAnswer((_) => messages.stream);
    when(() => localNotifications.init()).thenAnswer((_) async {});
    when(
      () => localNotifications.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async {});

    handler = ForegroundPushHandler(
      pushService: pushService,
      localNotifications: localNotifications,
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
      () => localNotifications.show(title: 'Market Alert', body: 'EUR/USD up'),
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
      () => localNotifications.show(title: 'Order filled', body: '500 AAPL'),
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
      ),
    );
  });
}
