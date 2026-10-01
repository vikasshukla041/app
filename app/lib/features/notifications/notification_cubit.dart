import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/secure_storage_service.dart';
import 'data/models/register_device_dto.dart';
import 'data/services/app_settings_service.dart';
import 'data/services/device_info_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/push_notification_service.dart';
import 'notification_state.dart';

enum NotificationResumeOutcome { unchanged, enabled, failed }

/// Owns the push-notification subscription logic.
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    PushNotificationService? pushService,
    NotificationService? notificationService,
    SecureStorageService? storageService,
    DeviceInfoService? deviceInfoService,
    AppSettingsService? appSettingsService,
  }) : _pushService = pushService ?? PushNotificationService(),
       _notificationService = notificationService ?? NotificationService(),
       _storageService = storageService ?? SecureStorageService(),
       _deviceInfoService = deviceInfoService ?? DeviceInfoService(),
       _appSettingsService = appSettingsService ?? AppSettingsService(),
       super(const NotificationInitial());

  final PushNotificationService _pushService;
  final NotificationService _notificationService;
  final SecureStorageService _storageService;
  final DeviceInfoService _deviceInfoService;
  final AppSettingsService _appSettingsService;

  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Asks for permission, then registers the token with the backend.
  Future<void> subscribe() async {
    if (isClosed || state is NotificationRequesting) {
      return;
    }

    emit(const NotificationRequesting());

    final String? platform = _pushService.platform;
    if (platform == null) {
      _log('No platform value; this host cannot register for push');
      // A Desktop host: the backend knows android, ios n web.
      _emitFailure(NotificationFailureReason.unavailable);
      return;
    }

    // read before asking so the two  answer can be compared.
    final PushPermissionResult before = await _pushService.currentPermission();

    final PushPermissionResult permission = await _pushService
        .requestPermission();
    _lastKnownPermission = permission;
    _log('Platform "$platform" reported permission $permission');

    switch (permission) {
      case PushPermissionResult.denied:
        _emitTransient(
          before == PushPermissionResult.denied
              ? const NotificationBlocked()
              : const NotificationDenied(),
        );
        return;
      case PushPermissionResult.unavailable:
        _log('Permission unavailable; see PushNotificationService above');
        _emitFailure(NotificationFailureReason.unavailable);
        return;
      case PushPermissionResult.granted:
        break;
    }

    final String? token = await _pushService.getToken();
    if (token == null || token.isEmpty) {
      _log('Permission granted but no token came back');
      // Granted but no token: Play Services missing, or FCM unreachable.
      _emitFailure(NotificationFailureReason.noToken);
      return;
    }

    await _register(token: token, platform: platform);
  }

  Future<void> openSettings() async {
    final bool opened = await _appSettingsService.openNotificationSettings();
    if (!opened && !isClosed) {
      _emitFailure(NotificationFailureReason.settingsUnavailable);
    }
  }

  PushPermissionResult? _lastKnownPermission;

  Future<NotificationResumeOutcome> refreshAfterResume() async {
    final String? platform = _pushService.platform;
    if (platform == null || isClosed) {
      return NotificationResumeOutcome.unchanged;
    }

    final PushPermissionResult permission = await _pushService
        .currentPermission();
    final PushPermissionResult? previous = _lastKnownPermission;
    _lastKnownPermission = permission;

    if (permission != PushPermissionResult.granted ||
        previous == null ||
        previous == PushPermissionResult.granted) {
      return NotificationResumeOutcome.unchanged;
    }

    final String? token = await _pushService.getToken();
    if (token == null || token.isEmpty) {
      return NotificationResumeOutcome.failed;
    }

    try {
      await _sendRegistration(token: token, platform: platform);
      return NotificationResumeOutcome.enabled;
    } catch (e, stackTrace) {
      _log('Registration after resume failed: $e', stackTrace);
      return NotificationResumeOutcome.failed;
    }
  }

  /// re-attaches this device token to whoever just signed in.
  /// Silent and never prompt
  Future<void> claimForCurrentUser() async {
    final String? platform = _pushService.platform;

    if (platform == null) {
      return;
    }

    final PushPermissionResult permission = await _pushService
        .currentPermission();

    _lastKnownPermission = permission;
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
    } on NotificationException catch (e, stackTrace) {
      _log('Device registration failed: ${e.reason}', stackTrace);
      _emitFailure(e.reason);
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

  /// Logs the reason only — never the token, which is a credential.
  void _log(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[NotificationCubit] $message');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// only used in test
  @override
  Future<void> close() async {
    await _tokenRefreshSubscription?.cancel();
    return super.close();
  }
}
