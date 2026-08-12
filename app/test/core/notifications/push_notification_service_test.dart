import 'dart:async';

import 'package:activotrade_app/core/notifications/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

class MockRemoteNotification extends Mock implements RemoteNotification {}

RemoteMessage _message({String? title, String? body}) {
  final MockRemoteMessage message = MockRemoteMessage();

  if (title == null && body == null) {
    when(() => message.notification).thenReturn(null);
    return message;
  }

  final MockRemoteNotification notification = MockRemoteNotification();
  when(() => notification.title).thenReturn(title);
  when(() => notification.body).thenReturn(body);
  when(() => message.notification).thenReturn(notification);
  return message;
}

void main() {
  late StreamController<RemoteMessage> incoming;
  late MockFirebaseMessaging messaging;
  late PushNotificationService service;

  setUp(() {
    incoming = StreamController<RemoteMessage>.broadcast();
    messaging = MockFirebaseMessaging();
    service = PushNotificationService(
      messaging: messaging,
      foregroundMessages: incoming.stream,
    );
  });

  tearDown(() async {
    await incoming.close();
  });

  group('onForegroundMessage', () {
    test('maps a notification block to PushMessage', () async {
      final Future<PushMessage> received = service.onForegroundMessage.first;

      incoming.add(_message(title: 'Market Alert', body: 'EUR/USD up'));

      final PushMessage message = await received;
      expect(message.title, 'Market Alert');
      expect(message.body, 'EUR/USD up');
    });

    test('drops data-only messages', () async {
      final Future<List<PushMessage>> collected = service.onForegroundMessage
          .toList();

      // A data-only push carries no notification block, so there is nothing
      // to draw. Forwarding it would post an empty banner.
      incoming.add(_message());
      incoming.add(_message(title: 'Order filled', body: '500 AAPL'));
      await incoming.close();

      final List<PushMessage> messages = await collected;
      expect(messages, hasLength(1));
      expect(messages.single.title, 'Order filled');
    });

    test('keeps a message that has only a title', () async {
      final Future<PushMessage> received = service.onForegroundMessage.first;

      incoming.add(_message(title: 'Margin call'));

      final PushMessage message = await received;
      expect(message.title, 'Margin call');
      expect(message.body, isEmpty);
    });
  });

  group('permission', () {
    test('maps authorized to granted', () async {
      when(
        () => messaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));

      expect(await service.requestPermission(), PushPermissionResult.granted);
    });

    test('maps a thrown platform error to unavailable, not denied', () async {
      // A device without Play Services cannot answer at all. Reporting that
      // as "denied" would tell the user they refused something they were
      // never asked.
      when(
        () => messaging.requestPermission(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenThrow(Exception('no play services'));

      expect(
        await service.requestPermission(),
        PushPermissionResult.unavailable,
      );
    });
  });

  group('getToken', () {
    test('returns null rather than fabricating a token on failure', () async {
      when(() => messaging.getToken()).thenThrow(Exception('fcm unreachable'));

      expect(await service.getToken(), isNull);
    });
  });
}

NotificationSettings _settings(AuthorizationStatus status) =>
    NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: status,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
