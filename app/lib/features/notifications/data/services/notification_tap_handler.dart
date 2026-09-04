import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/routing/deep_link_controller.dart';
import '../../../../core/routing/deep_link_parser.dart';
import 'local_notifications_service.dart';
import 'push_notification_service.dart';

/// Turns a tapped notification, from any app state, into a route to open.
class NotificationTapHandler {
  NotificationTapHandler({
    required this._pushService,
    required this._localNotifications,
    required this._deepLinks,
  });

  /// Longest time to wait for the cold-boot notification check.
  static const Duration _coldBootBudget = Duration(seconds: 3);

  final PushNotificationService _pushService;
  final LocalNotificationsService _localNotifications;
  final DeepLinkController _deepLinks;

  StreamSubscription<PushMessage>? _openedAppSubscription;
  StreamSubscription<Map<String, String>>? _foregroundTapSubscription;

  /// Stops two calls at once from both starting the same subscriptions.
  bool _starting = false;

  /// Safe to call again; never throws, so at worst deep-linking is lost.
  Future<void> start() async {
    if (_openedAppSubscription != null || _starting) {
      return;
    }
    _starting = true;

    try {
      _openedAppSubscription = _pushService.onNotificationTap.listen(
        (PushMessage message) => _route(message.data),
      );
      _foregroundTapSubscription = _localNotifications.onTap.listen(_route);

      // Check this last since it only ever fires once, on a cold boot.
      final PushMessage? launch = await _pushService
          .initialMessage()
          .then<PushMessage?>((PushMessage? message) => message)
          .timeout(_coldBootBudget, onTimeout: () => null);

      if (launch != null) {
        _route(launch.data);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[tapHandler] Could not start: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _starting = false;
    }
  }

  void _route(Map<String, String> data) {
    final String? location = DeepLinkParser.parse(data);

    if (location == null) {
      // No matching route, so just open the app normally.
      return;
    }
    _deepLinks.push(location);
  }

  /// Only reached in tests — this handler lives for the whole process.
  Future<void> stop() async {
    await _openedAppSubscription?.cancel();
    await _foregroundTapSubscription?.cancel();
    _openedAppSubscription = null;
    _foregroundTapSubscription = null;
  }
}
