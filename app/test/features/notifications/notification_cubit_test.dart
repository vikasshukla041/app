import 'dart:async';

import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/features/notifications/data/models/register_device_dto.dart';
import 'package:activotrade_app/features/notifications/data/services/app_settings_service.dart';
import 'package:activotrade_app/features/notifications/data/services/device_info_service.dart';
import 'package:activotrade_app/features/notifications/data/services/notification_service.dart';
import 'package:activotrade_app/features/notifications/data/services/push_notification_service.dart';
import 'package:activotrade_app/features/notifications/notification_cubit.dart';
import 'package:activotrade_app/features/notifications/notification_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class MockAppSettingsService extends Mock implements AppSettingsService {}

void main() {
  late MockPushNotificationService pushService;
  late MockNotificationService notificationService;
  late MockSecureStorageService storage;
  late MockDeviceInfoService deviceInfo;
  late MockAppSettingsService appSettings;

  NotificationCubit buildCubit() => NotificationCubit(
    pushService: pushService,
    notificationService: notificationService,
    storageService: storage,
    deviceInfoService: deviceInfo,
    appSettingsService: appSettings,
  );

  setUpAll(() {
    // any() needs a fallback for a non-primitive argument.
    registerFallbackValue(
      const RegisterDeviceDto(
        fcmToken: 'x',
        deviceId: 'x',
        platform: 'android',
        deviceName: 'x',
      ),
    );
  });

  setUp(() {
    pushService = MockPushNotificationService();
    notificationService = MockNotificationService();
    storage = MockSecureStorageService();
    deviceInfo = MockDeviceInfoService();
    appSettings = MockAppSettingsService();

    when(() => pushService.platform).thenReturn('android');
    when(() => pushService.onTokenRefresh).thenAnswer(
      (_) => const Stream<String>.empty(),
    );
  });

  group('subscribe tells a fresh denial from a blocked one', () {
    // Neither Android nor iOS reports "permanently denied" directly. Reading
    // the permission before and after asking is the only signal: unchanged
    // means the OS never showed its dialog.

    blocTest<NotificationCubit, NotificationState>(
      'denied after being undecided is NotificationDenied — the bell can '
      'still ask again',
      setUp: () {
        when(() => pushService.currentPermission()).thenAnswer(
          (_) async => PushPermissionResult.granted,
        );
        when(() => pushService.requestPermission()).thenAnswer(
          (_) async => PushPermissionResult.denied,
        );
      },
      build: buildCubit,
      act: (NotificationCubit cubit) => cubit.subscribe(),
      expect: () => <NotificationState>[
        const NotificationRequesting(),
        const NotificationDenied(),
        const NotificationInitial(),
      ],
    );

    blocTest<NotificationCubit, NotificationState>(
      'denied before and after is NotificationBlocked — only settings can '
      'help now',
      setUp: () {
        when(() => pushService.currentPermission()).thenAnswer(
          (_) async => PushPermissionResult.denied,
        );
        when(() => pushService.requestPermission()).thenAnswer(
          (_) async => PushPermissionResult.denied,
        );
      },
      build: buildCubit,
      act: (NotificationCubit cubit) => cubit.subscribe(),
      expect: () => <NotificationState>[
        const NotificationRequesting(),
        const NotificationBlocked(),
        const NotificationInitial(),
      ],
    );
  });

  group('openSettings', () {
    blocTest<NotificationCubit, NotificationState>(
      'stays silent when the settings page opened',
      setUp: () {
        when(() => appSettings.openNotificationSettings()).thenAnswer(
          (_) async => true,
        );
      },
      build: buildCubit,
      act: (NotificationCubit cubit) => cubit.openSettings(),
      expect: () => <NotificationState>[],
    );

    blocTest<NotificationCubit, NotificationState>(
      'reports a failure when nothing opened, rather than a dead button',
      setUp: () {
        when(() => appSettings.openNotificationSettings()).thenAnswer(
          (_) async => false,
        );
      },
      build: buildCubit,
      act: (NotificationCubit cubit) => cubit.openSettings(),
      expect: () => <NotificationState>[
        const NotificationFailure(
          NotificationFailureReason.settingsUnavailable,
        ),
        const NotificationInitial(),
      ],
    );
  });

  group('refreshAfterResume', () {
    // Returns its outcome instead of emitting: on a resume there is no dialog
    // on screen, so an emitted state would have nobody listening.

    test('returns unchanged when the permission is still denied', () async {
      when(() => pushService.currentPermission()).thenAnswer(
        (_) async => PushPermissionResult.denied,
      );

      final NotificationCubit cubit = buildCubit();

      expect(
        await cubit.refreshAfterResume(),
        NotificationResumeOutcome.unchanged,
      );
      verifyNever(() => pushService.getToken());
    });

    test('returns enabled once the user turned it on in settings', () async {
      when(() => pushService.currentPermission()).thenAnswer(
        (_) async => PushPermissionResult.granted,
      );
      when(() => pushService.getToken()).thenAnswer((_) async => 'token_1');
      when(() => storage.getOrCreateDeviceId()).thenAnswer(
        (_) async => 'device_1',
      );
      when(() => deviceInfo.deviceName()).thenAnswer((_) async => 'Pixel');
      when(() => notificationService.registerDevice(any())).thenAnswer(
        (_) async {},
      );

      final NotificationCubit cubit = buildCubit();

      expect(
        await cubit.refreshAfterResume(),
        NotificationResumeOutcome.enabled,
      );
    });

    test('does not register again when nothing changed', () async {
      when(() => pushService.currentPermission()).thenAnswer(
        (_) async => PushPermissionResult.granted,
      );
      when(() => pushService.getToken()).thenAnswer((_) async => 'token_1');
      when(() => storage.getOrCreateDeviceId()).thenAnswer(
        (_) async => 'device_1',
      );
      when(() => deviceInfo.deviceName()).thenAnswer((_) async => 'Pixel');
      when(() => notificationService.registerDevice(any())).thenAnswer(
        (_) async {},
      );

      final NotificationCubit cubit = buildCubit();

      expect(
        await cubit.refreshAfterResume(),
        NotificationResumeOutcome.enabled,
      );
      // Every app foreground calls this; only a change should do any work.
      expect(
        await cubit.refreshAfterResume(),
        NotificationResumeOutcome.unchanged,
      );
      verify(() => notificationService.registerDevice(any())).called(1);
    });

    test('returns failed when registering the device did not work', () async {
      when(() => pushService.currentPermission()).thenAnswer(
        (_) async => PushPermissionResult.granted,
      );
      when(() => pushService.getToken()).thenAnswer((_) async => 'token_1');
      when(() => storage.getOrCreateDeviceId()).thenAnswer(
        (_) async => 'device_1',
      );
      when(() => deviceInfo.deviceName()).thenAnswer((_) async => 'Pixel');
      when(() => notificationService.registerDevice(any())).thenThrow(
        const NotificationException(NotificationFailureReason.network),
      );

      final NotificationCubit cubit = buildCubit();

      expect(
        await cubit.refreshAfterResume(),
        NotificationResumeOutcome.failed,
      );
    });
  });
}
