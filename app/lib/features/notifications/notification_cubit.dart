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

/// Owns the push-notification subscription logic.
///
/// Nothing here fabricates a token. If the platform cannot issue one, that
/// surfaces as a failure state the user can read — a fake token would be
/// registered with the backend, fail on first dispatch, and be auto-purged,
/// while the user was told it worked.
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
    if (state is NotificationRequesting) {
      return;
    }

    emit(const NotificationRequesting());

    final String? platform = _pushService.platform;
    if (platform == null) {
      // Desktop or web host: the backend only knows android and ios.
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

  Future<void> _register({
    required String token,
    required String platform,
  }) async {
    try {
      await _notificationService.registerDevice(
        RegisterDeviceDto(
          fcmToken: token,
          deviceId: await _storageService.getOrCreateDeviceId(),
          platform: platform,
          deviceName: await _deviceInfoService.deviceName(),
        ),
      );

      _listenForTokenRotation();
      _emitTransient(const NotificationRegistered());
    } on DioException catch (e, stackTrace) {
      _log('Device registration failed: ${e.type}', stackTrace);
      _emitFailure(_mapDioError(e));
    } catch (e, stackTrace) {
      _log('Device registration failed: $e', stackTrace);
      _emitFailure(NotificationFailureReason.registrationFailed);
    }
  }

  /// FCM rotates tokens on reinstall and restore. Re-registering keeps the
  /// backend from holding one that silently stopped delivering.
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

  /// Logs the reason only — never the token, which is a credential.
  void _log(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[NotificationCubit] $message');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  Future<void> close() {
    _tokenRefreshSubscription?.cancel();
    return super.close();
  }
}
