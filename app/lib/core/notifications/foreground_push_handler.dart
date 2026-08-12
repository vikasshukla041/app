import 'dart:async';

import 'package:flutter/foundation.dart';

import 'local_notifications_service.dart';
import 'push_notification_service.dart';

/// Connect incoming foreground pushes to local banner
class ForegroundPushHandler {
  ForegroundPushHandler({
    required this._pushService,
    required this._localNotifications,
  });

  final PushNotificationService _pushService;
  final LocalNotificationsService _localNotifications;

  StreamSubscription<PushMessage>? _subscription;

  /// Raised before the first await, so two concurrent calls cannot both reach
  /// the subscription. Checking `_subscription` alone would not do it: that
  /// field is assigned after an await, so both callers would still see null
  /// and every banner would be drawn twice.
  bool _starting = false;

  /// Safe to call more than once; every call after the first is a no-op.
  ///
  /// Never throws. It is launched unawaited from main(), so an escaping error
  /// would surface as an unhandled zone error. Push failing must not break
  /// start-up.
  Future<void> start() async {
    if (_subscription != null || _starting) {
      return;
    }
    _starting = true;

    try {
      await _localNotifications.init();

      _subscription = _pushService.onForegroundMessage.listen(
        (PushMessage message) =>
            _localNotifications.show(title: message.title, body: message.body),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ForegroundPushHandler] Could not start: $e');
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
