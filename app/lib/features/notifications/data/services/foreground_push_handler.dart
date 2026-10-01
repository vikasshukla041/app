import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/auth/app_auth_cubit.dart';
import '../../../../core/auth/app_auth_state.dart';
import 'local_notifications_service.dart';
import 'push_notification_service.dart';

/// Connects incoming foreground push notifications to local notifications.
///
/// This handler is responsible only for foreground messages.
/// Background and cold-boot notification taps are handled separately by
/// NotificationTapHandler.
class ForegroundPushHandler {
  ForegroundPushHandler({
    required this._pushService,
    required this._localNotifications,
    required this._appAuthCubit,
  });

  /// Service that receives messages from Firebase Cloud Messaging.
  final PushNotificationService _pushService;

  /// Service used to display a local notification while the app is
  /// in the foreground.
  final LocalNotificationsService _localNotifications;

  /// Current app-level authentication state.
  ///
  /// We use this to prevent notifications belonging to a previous session
  /// from being shown after the user has logged out.
  final AppAuthCubit _appAuthCubit;

  /// Subscription to the foreground FCM message stream.
  StreamSubscription<PushMessage>? _subscription;

  /// Prevents start() from running twice at the same time.
  bool _starting = false;

  /// Starts listening for foreground push notifications.
  ///
  /// Calling this method more than once is safe. Only one subscription
  /// will be created.
  Future<void> start() async {
    if (_subscription != null || _starting) {
      return;
    }

    _starting = true;

    try {
      // Local notifications must be initialized before we try to show
      // any foreground notification.
      await _localNotifications.init();

      // Listen for Firebase messages received while the app is open.
      _subscription = _pushService.onForegroundMessage.listen(_onMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ForegroundPushHandler] could not start: $e');
      }
    } finally {
      _starting = false;
    }
  }

  /// Handles a single foreground push message.
  ///
  /// A notification is shown only when there is currently an authenticated
  /// user. This prevents a logged-out user from seeing notifications that
  /// belong to the previous session.
  void _onMessage(PushMessage message) {
    // Do not show foreground notifications when there is no active session.
    //
    // This check is important because the device can still receive FCM
    // messages even after the user has logged out.
    if (_appAuthCubit.state is! AppAuthenticated) {
      _log('Dropped a foreground push: no signed-in user');
      return;
    }

    // Show the notification without blocking the FCM stream.
    //
    // The message data is passed as the notification payload so the local
    // notification tap handler can use the same deep-link information.
    unawaited(
      _localNotifications.show(
        title: message.title,
        body: message.body,
        payload: message.data,
      ),
    );
  }

  /// Stops listening for foreground push notifications.
  ///
  /// Normally this handler lives for the whole application lifetime,
  /// but this method is useful for tests and controlled shutdown.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Writes debug-only logs.
  ///
  /// No notification credentials or FCM tokens are logged here.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ForegroundPushHandler] $message');
    }
  }
}
