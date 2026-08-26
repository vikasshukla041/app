// FirebaseException lives in firebase_core, not firebase_messaging.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Result of asking for notification permission, simplified to 3 outcomes.
enum PushPermissionResult { granted, denied, unavailable }

/// One push notification, reduced to a title and body.
class PushMessage {
  const PushMessage({required this.title, required this.body});

  final String title;
  final String body;
}

/// Wraps Firebase Cloud Messaging (FCM) push notifications.
class PushNotificationService {
  /// Lets tests inject fake streams, since FCM's real streams are static.
  PushNotificationService({
    FirebaseMessaging? messaging,
    Stream<RemoteMessage>? foregroundMessages,
  }) : _injected = messaging,
       _injectedForeground = foregroundMessages;

  final FirebaseMessaging? _injected;
  final Stream<RemoteMessage>? _injectedForeground;

  FirebaseMessaging? _resolved;
  bool _tried = false;

  /// Loads Firebase lazily, so a missing Firebase setup cannot crash start-up.
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

  /// Asks OS for permission.
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

  /// Fires when FCM gives a new token; empty if Firebase never started.
  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream<String>.empty();

  Stream<PushMessage> get onForegroundMessage {
    final Stream<RemoteMessage>? incoming =
        _injectedForeground ?? _firebaseForeground();
    if (incoming == null) {
      return const Stream<PushMessage>.empty();
    }

    return incoming
        .map(
          (RemoteMessage m) => PushMessage(
            title: m.notification?.title ?? '',
            body: m.notification?.body ?? '',
          ),
        )
        .where((PushMessage m) => m.title.isNotEmpty || m.body.isNotEmpty);
  }

  /// Wraps a static FCM stream getter so a missing Firebase does not crash.
  Stream<RemoteMessage>? _firebaseForeground() {
    try {
      return FirebaseMessaging.onMessage;
    } catch (e) {
      _log('Foreground stream unavailable: $e');
      return null;
    }
  }

  /// Returns 'android', 'ios', or 'web' — the values the backend accepts.
  String? get platform {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  /// Logs only the error reason; the FCM token itself must never be logged.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PushNotificationService] $message');
    }
  }
}
