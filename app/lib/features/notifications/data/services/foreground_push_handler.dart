import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/auth/app_auth_cubit.dart';
import '../../../../core/auth/app_auth_state.dart';
import 'local_notifications_service.dart';
import 'push_notification_service.dart';

/// Connects an incoming foreground push to a local banner.
///
/// A push is addressed to an account, but the device stays subscribed after
/// sign-out, so every message is gated on there being a live session.
class ForegroundPushHandler {
  ForegroundPushHandler({
    required this._pushService,
    required this._localNotifications,
    required this._appAuthCubit,
  });

  final PushNotificationService _pushService;
  final LocalNotificationsService _localNotifications;
  final AppAuthCubit _appAuthCubit;

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

      _subscription = _pushService.onForegroundMessage.listen(_onMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ForegroundPushHandler] Could not start: $e');
      }
    } finally {
      _starting = false;
    }
  }

  /// Drops anything that arrives without a live session.
  ///
  /// Locked counts as no session: the app is on screen behind the unlock
  /// prompt, so a banner there would defeat the lock it is sitting on.
  void _onMessage(PushMessage message) {
    if (_appAuthCubit.state is! AppAuthenticated) {
      _log('Dropped a foreground push: no signed-in user');
      return;
    }
    unawaited(
      _localNotifications.show(title: message.title, body: message.body),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Logs the reason only — a push body may carry account information.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ForegroundPushHandler] $message');
    }
  }
}
