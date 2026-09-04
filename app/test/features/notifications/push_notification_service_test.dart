import 'dart:async';

import 'package:activotrade_app/features/notifications/data/services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

class MockRemoteNotification extends Mock implements RemoteNotification {}

RemoteMessage _message({
  String? title,
  String? body,
  Map<String, dynamic> data = const <String, dynamic>{},
}) {
  final MockRemoteMessage message = MockRemoteMessage();
  when(() => message.data).thenReturn(data);

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

      // A data-only push has nothing to show, so do not draw an empty banner.
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

  group('onNotificationTap', () {
    test('carries the data payload through unchanged', () async {
      final StreamController<RemoteMessage> opened =
          StreamController<RemoteMessage>.broadcast();
      addTearDown(opened.close);

      final PushNotificationService tapService = PushNotificationService(
        messaging: messaging,
        openedAppMessages: opened.stream,
      );
      final Future<PushMessage> received = tapService.onNotificationTap.first;

      opened.add(
        _message(
          title: 'Order filled',
          data: <String, dynamic>{'route': '/dashboard', 'id': '42'},
        ),
      );

      final PushMessage message = await received;
      expect(message.data['route'], '/dashboard');
      expect(message.data['id'], '42');
    });

    test('keeps a data-only tap, unlike a foreground message', () async {
      final StreamController<RemoteMessage> opened =
          StreamController<RemoteMessage>.broadcast();
      addTearDown(opened.close);

      final PushNotificationService tapService = PushNotificationService(
        messaging: messaging,
        openedAppMessages: opened.stream,
      );
      final Future<PushMessage> received = tapService.onNotificationTap.first;

      // A tap must never be filtered, since that would drop the route it carries.
      opened.add(_message(data: <String, dynamic>{'route': '/dashboard'}));

      final PushMessage message = await received;
      expect(message.title, isEmpty);
      expect(message.data['route'], '/dashboard');
    });

    test('drops non-string payload values, never stringifies', () async {
      final StreamController<RemoteMessage> opened =
          StreamController<RemoteMessage>.broadcast();
      addTearDown(opened.close);

      final PushNotificationService tapService = PushNotificationService(
        messaging: messaging,
        openedAppMessages: opened.stream,
      );
      final Future<PushMessage> received = tapService.onNotificationTap.first;

      // Otherwise a null would arrive at the parser as the string "null".
      opened.add(
        _message(
          data: <String, dynamic>{'route': '/dashboard', 'id': null, 'n': 7},
        ),
      );

      final PushMessage message = await received;
      expect(message.data.containsKey('id'), isFalse);
      expect(message.data.containsKey('n'), isFalse);
      expect(message.data['route'], '/dashboard');
    });
  });

  group('initialMessage', () {
    test('returns null rather than throwing when the lookup fails', () async {
      when(() => messaging.getInitialMessage()).thenThrow(Exception('no fcm'));

      expect(await service.initialMessage(), isNull);
    });

    test('maps the launching notification when there is one', () async {
      when(() => messaging.getInitialMessage()).thenAnswer(
        (_) async =>
            _message(title: 'Margin call', data: <String, dynamic>{'id': '5'}),
      );

      final PushMessage? message = await service.initialMessage();
      expect(message?.title, 'Margin call');
      expect(message?.data['id'], '5');
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
      // A device that cannot ask at all is not the same as one that says no.
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

  group('platform', () {
    test('reports the host platform for the backend', () async {
      // The web branch cannot run in a VM test; check it by running in a browser.
      expect(service.platform, anyOf('android', 'ios'));
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
