import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Result of asking for notification permission, simplified to 3 outcomes.
enum PushPermissionResult { granted, denied, unavailable }

/// One notification, reduced to what the app actually uses.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    this.data = const <String, String>{},
  });

  /// Builds a PushMessage from raw FCM data, dropping any non-string values.
  factory PushMessage.fromRemote(RemoteMessage message) {
    return PushMessage(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: <String, String>{
        for (final MapEntry<String, dynamic> entry in message.data.entries)
          // FCM data values should be strings; anything else is dropped, never cast.
          if (entry.value is String) entry.key: entry.value as String,
      },
    );
  }

  final String title;
  final String body;

  /// The FCM data payload.
  final Map<String, String> data;
}

/// Wraps Firebase Cloud Messaging (FCM) push notifications.
class PushNotificationService {
  /// Lets tests inject fake streams, since FCM's real streams are static.
  PushNotificationService({
    FirebaseMessaging? messaging,
    Stream<RemoteMessage>? foregroundMessages,
    Stream<RemoteMessage>? openedAppMessages,
  }) : _injected = messaging,
       _injectedForeground = foregroundMessages,
       _injectedOpenedApp = openedAppMessages;

  final FirebaseMessaging? _injected;
  final Stream<RemoteMessage>? _injectedForeground;
  final Stream<RemoteMessage>? _injectedOpenedApp;

  FirebaseMessaging? _resolved;
  bool _tried = false;

  /// Loads Firebase lazily, so missing Firebase setup cannot crash startup.
  FirebaseMessaging? get _messaging {
    if (_injected != null) {
      return _injected;
    }

    if (!_tried) {
      _tried = true;

      try {
        _resolved = FirebaseMessaging.instance;
      } catch (e) {
        _log('Firebase unavailable: $e');
      }
    }

    return _resolved;
  }

  /// Asks the OS for notification permission.
  Future<PushPermissionResult> requestPermission() async {
    final FirebaseMessaging? messaging = _messaging;

    if (messaging == null) {
      return PushPermissionResult.unavailable;
    }

    try {
      final NotificationSettings settings = await messaging.requestPermission();

      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermissionResult.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.notDetermined => PushPermissionResult.denied,
      };
    } on FirebaseException catch (e) {
      _log('Permission request failed: ${e.code}');
      return PushPermissionResult.unavailable;
    } catch (e) {
      _log('Permission request failed: $e');
      return PushPermissionResult.unavailable;
    }
  }

  /// Reads the existing permission without showing a prompt.
  Future<PushPermissionResult> currentPermission() async {
    final FirebaseMessaging? messaging = _messaging;

    if (messaging == null) {
      return PushPermissionResult.unavailable;
    }

    try {
      final NotificationSettings settings = await messaging
          .getNotificationSettings();

      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermissionResult.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.notDetermined => PushPermissionResult.denied,
      };
    } catch (e) {
      _log('Permission read failed: $e');
      return PushPermissionResult.unavailable;
    }
  }

  /// Returns null on failure instead of making up a fake token.
  Future<String?> getToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      _log('Token fetch failed: $e');
      return null;
    }
  }

  /// Fires when FCM gives a new token.
  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream<String>.empty();

  /// Fires only while the app is in the foreground.
  ///
  /// Data is preserved because foreground_push_handler.dart forwards it to
  /// the local notification payload.
  Stream<PushMessage> get onForegroundMessage {
    final Stream<RemoteMessage>? incoming =
        _injectedForeground ??
        _firebaseStream(() => FirebaseMessaging.onMessage);

    if (incoming == null) {
      return const Stream<PushMessage>.empty();
    }

    return incoming
        .map(PushMessage.fromRemote)
        .where(
          (PushMessage message) =>
              message.title.isNotEmpty || message.body.isNotEmpty,
        );
  }

  /// Fires when the user taps a notification while the app is backgrounded.
  Stream<PushMessage> get onNotificationTap {
    final Stream<RemoteMessage>? incoming =
        _injectedOpenedApp ??
        _firebaseStream(() => FirebaseMessaging.onMessageOpenedApp);

    if (incoming == null) {
      return const Stream<PushMessage>.empty();
    }

    return incoming.map(PushMessage.fromRemote);
  }

  /// Returns the notification that launched a killed app, if any.
  Future<PushMessage?> initialMessage() async {
    final FirebaseMessaging? messaging = _messaging;

    if (messaging == null) {
      return null;
    }

    try {
      final RemoteMessage? message = await messaging.getInitialMessage();

      return message == null ? null : PushMessage.fromRemote(message);
    } catch (e) {
      _log('Initial message lookup failed: $e');
      return null;
    }
  }

  /// Wraps static Firebase streams so missing Firebase does not crash startup.
  Stream<RemoteMessage>? _firebaseStream(
    Stream<RemoteMessage> Function() source,
  ) {
    try {
      return source();
    } catch (e) {
      _log('Message stream unavailable: $e');
      return null;
    }
  }

  /// `'android'`, `'ios'`, or null when unsupported/web.
  String? get platform {
    if (kIsWeb) {
      return 'web';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    }

    return null;
  }

  /// Never log FCM tokens or other credentials.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PushNotificationService] $message');
    }
  }
}
