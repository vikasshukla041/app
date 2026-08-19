import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/device/device_info_service.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../core/storage/secure_storage_service.dart';
import 'data/models/register_device_dto.dart';
import 'data/services/notification_service.dart';
import 'notification_state.dart';

/// Owns the push-notification subscription logic; never fakes a token on failure.
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    PushNotificationService? pushService,
    NotificationService? notificationService,
    SecureStorageService? storageService,
    DeviceInfoService? deviceInfoService,
  }) : _pushService = pushService ?? PushNotificationService(),
       _notificationService = notificationService ?? NotificationService(),
       _storageService = storageService ?? SecureStorageService(),
       _deviceInfoService = deviceInfoService ?? DeviceInfoService(),
       super(const NotificationInitial());

  final PushNotificationService _pushService;
  final NotificationService _notificationService;
  final SecureStorageService _storageService;
  final DeviceInfoService _deviceInfoService;

  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Asks for permission, then registers the token with the backend.
  Future<void> subscribe() async {
    // Guard against double taps and a dialog that closed before this ran.
    if (isClosed || state is NotificationRequesting) {
      return;
    }

    emit(const NotificationRequesting());

    final String? platform = _pushService.platform;
    if (platform == null) {
      // A desktop host: the backend knows android, ios and web, nothing else.
      _emitFailure(NotificationFailureReason.unavailable);
      return;
    }

    final PushPermissionResult permission = await _pushService
        .requestPermission();

    switch (permission) {
      case PushPermissionResult.denied:
        _emitTransient(const NotificationDenied());
        return;
      case PushPermissionResult.unavailable:
        _emitFailure(NotificationFailureReason.unavailable);
        return;
      case PushPermissionResult.granted:
        break;
    }

    final String? token = await _pushService.getToken();
    if (token == null || token.isEmpty) {
      // Granted but no token: Play Services missing, or FCM unreachable.
      _emitFailure(NotificationFailureReason.noToken);
      return;
    }

    await _register(token: token, platform: platform);
  }

  /// Re-attaches this device's token to whoever just signed in; silent, and never prompts.
  Future<void> claimForCurrentUser() async {
    final String? platform = _pushService.platform;
    if (platform == null) {
      return;
    }

    final PushPermissionResult permission = await _pushService
        .currentPermission();
    if (permission != PushPermissionResult.granted) {
      return;
    }

    final String? token = await _pushService.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _sendRegistration(token: token, platform: platform);
    } catch (e, stackTrace) {
      // Nothing to surface: the user never asked for this to happen.
      _log('Token claim failed: $e', stackTrace);
    }
  }

  /// Posts the registration and starts watching for rotations; shared by [subscribe] and [claimForCurrentUser].
  Future<void> _sendRegistration({
    required String token,
    required String platform,
  }) async {
    await _notificationService.registerDevice(
      RegisterDeviceDto(
        fcmToken: token,
        deviceId: await _storageService.getOrCreateDeviceId(),
        platform: platform,
        deviceName: await _deviceInfoService.deviceName(),
      ),
    );
    _listenForTokenRotation();
  }

  Future<void> _register({
    required String token,
    required String platform,
  }) async {
    try {
      await _sendRegistration(token: token, platform: platform);
      _emitTransient(const NotificationRegistered());
    } on DioException catch (e, stackTrace) {
      _log('Device registration failed: ${e.type}', stackTrace);
      _emitFailure(_mapDioError(e));
    } catch (e, stackTrace) {
      _log('Device registration failed: $e', stackTrace);
      _emitFailure(NotificationFailureReason.registrationFailed);
    }
  }

  /// Re-registers when FCM rotates the token, so the backend never holds a dead one.
  void _listenForTokenRotation() {
    _tokenRefreshSubscription ??= _pushService.onTokenRefresh.listen((
      String token,
    ) {
      final String? platform = _pushService.platform;
      if (platform != null) {
        unawaited(_register(token: token, platform: platform));
      }
    });
  }

  void _emitFailure(NotificationFailureReason reason) =>
      _emitTransient(NotificationFailure(reason));

  void _emitTransient(NotificationState outcome) {
    if (isClosed) {
      return;
    }
    emit(outcome);
    emit(const NotificationInitial());
  }

  NotificationFailureReason _mapDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => NotificationFailureReason.network,
      _ => NotificationFailureReason.registrationFailed,
    };
  }

  /// Logs only the error reason; the token itself must never be logged.
  void _log(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[NotificationCubit] $message');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// Only used in tests; waits for the subscription to cancel so tests do not leak it.
  @override
  Future<void> close() async {
    await _tokenRefreshSubscription?.cancel();
    return super.close();
  }
}
