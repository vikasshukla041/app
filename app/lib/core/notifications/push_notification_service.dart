import 'dart:io' show Platform;

// FirebaseException lives in firebase_core, not firebase_messaging.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Outcome of asking the OS for notification permission.
///
/// firebase_messaging surfaces a wider set of statuses and platform errors;
/// they collapse to these three so NotificationCubit never imports Firebase.
enum PushPermissionResult { granted, denied, unavailable }

/// A
class PushMessage {
  const PushMessage({required this.title, required this.body});

  final String title;
  final String body;
}

/// 'Firebase_messagaing'- notification
class PushNotificationService {
  /// foreground messages inject bcoz fbm is static
  PushNotificationService({
    FirebaseMessaging? messaging,
    Stream<RemoteMessage>? foregroundMessages,
  }) : _injected = messaging,
       _injectedForeground = foregroundMessages;

  final FirebaseMessaging? _injected;
  final Stream<RemoteMessage>? _injectedForeground;

  FirebaseMessaging? _resolved;
  bool _tried = false;

  /// Resolved on first use, never in the constructor. `.instance` throws
  /// [core/no-app] when Firebase never started, and the service locator builds
  /// this during start-up — throwing there stops runApp() and blacks out the
  /// app instead of just costing it push.
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

  /// Never fabricates a value — a null answer is the truth, and the caller
  /// needs it to tell the user something honest.
  Future<String?> getToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      _log('Token fetch failed: $e');
      return null;
    }
  }

  /// Fires whenever FCM rotates the token — reinstall, restore from backup,
  /// or at Google's discretion. Empty when Firebase never started.
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

  /// Static, so it cannot go through [_messaging] — but fails the same way
  /// when Firebase never started.
  Stream<RemoteMessage>? _firebaseForeground() {
    try {
      return FirebaseMessaging.onMessage;
    } catch (e) {
      _log('Foreground stream unavailable: $e');
      return null;
    }
  }

  /// `'android'` or `'ios'` — the only two values the backend accepts.
  String? get platform {
    if (kIsWeb) {
      return null;
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return null;
  }

  /// Logs the reason only — an FCM token is a credential and must never reach
  /// the device log.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PushNotificationService] $message');
    }
  }
}
