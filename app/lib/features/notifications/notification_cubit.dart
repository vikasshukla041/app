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

/// What a resume-time permission re-check found.
///
/// Returned rather than emitted, because a resume happens with no dialog on
/// screen and therefore with nothing listening to the cubit.
enum NotificationResumeOutcome {
  /// The permission is the same as it was; the user is not waiting on anything.
  unchanged,

  /// Newly granted in the OS settings, and the device is registered.
  enabled,

  /// Newly granted, but registering the device did not work.
  failed,
}

/// Owns the push-notification subscription logic; never fakes a token on failure.
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
    // Guard against double taps and a dialog that closed before this ran.
    if (isClosed || state is NotificationRequesting) {
      return;
    }

    emit(const NotificationRequesting());

    final String? platform = _pushService.platform;
    if (platform == null) {
      // A desktop host: the backend knows android, ios and web, nothing else.
      _log('No platform value; this host cannot register for push');
      _emitFailure(NotificationFailureReason.unavailable);
      return;
    }

    // Read before asking, so the two answers can be compared below.
    final PushPermissionResult before = await _pushService.currentPermission();

    final PushPermissionResult permission = await _pushService
        .requestPermission();
    _lastKnownPermission = permission;
    _log('Platform "$platform" reported permission $permission');

    switch (permission) {
      case PushPermissionResult.denied:
        // Denied before and after means the OS never showed its dialog: it
        // stops asking once the user has refused. Neither Android nor iOS
        // reports that state directly, so the pair of reads is the only
        // signal — and the difference matters, because the bell can still
        // help in one case and cannot in the other.
        _emitTransient(
          before == PushPermissionResult.denied
              ? const NotificationBlocked()
              : const NotificationDenied(),
        );
        return;
      case PushPermissionResult.unavailable:
        // Firebase never started, or the permission API threw.
        _log('Permission unavailable; see PushNotificationService above');
        _emitFailure(NotificationFailureReason.unavailable);
        return;
      case PushPermissionResult.granted:
        break;
    }

    final String? token = await _pushService.getToken();
    if (token == null || token.isEmpty) {
      // Granted but no token: Play Services missing, or FCM unreachable.
      _log('Permission granted but no token came back');
      _emitFailure(NotificationFailureReason.noToken);
      return;
    }

    await _register(token: token, platform: platform);
  }

  /// Takes the user to the OS page where notifications can be turned back on.
  ///
  /// The app can never grant the permission itself; this only opens the place
  /// where the user can. Fails to a message rather than a dead button.
  Future<void> openSettings() async {
    final bool opened = await _appSettingsService.openNotificationSettings();
    if (!opened && !isClosed) {
      // Web, or a device with no settings screen for this intent.
      _emitFailure(NotificationFailureReason.settingsUnavailable);
    }
  }

  /// The last permission this cubit saw, so a resume can tell a change from a
  /// repeat. Null until something has asked.
  PushPermissionResult? _lastKnownPermission;

  /// Re-reads the permission after the user has been to the OS settings.
  ///
  /// Only acts on a change into [PushPermissionResult.granted]. Without that
  /// check this would re-register on every single app foreground — and on web,
  /// on every tab focus.
  ///
  /// Returns its outcome rather than emitting one. A resume happens with no
  /// dialog on screen, so nothing is listening to this cubit at that moment —
  /// an emitted state would simply be lost. The caller shows the message.
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
      // The user enabled this in settings, so a failure here is worth showing.
      _log('Registration after resume failed: $e', stackTrace);
      return NotificationResumeOutcome.failed;
    }
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

  /// Posts the registration and starts watching for rotations; shared by
  /// [subscribe] and [claimForCurrentUser].
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
