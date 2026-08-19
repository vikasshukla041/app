import 'package:get_it/get_it.dart';

import '../../features/auth/auth_cubit.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/dashboard/dashboard_cubit.dart';
import '../../features/notifications/data/services/notification_service.dart';
import '../../features/notifications/notification_cubit.dart';
import '../auth/app_auth_cubit.dart';
import '../device/device_info_service.dart';
import '../network/api_service.dart';
import '../notifications/foreground_push_handler.dart';
import '../notifications/local_notifications_service.dart';
import '../notifications/push_notification_service.dart';
import '../security/biometric_service.dart';
import '../storage/secure_storage_service.dart';

final GetIt getIt = GetIt.instance;

/// Sets up global dependency injection instances using GetIt.
void setupServiceLocator() {
  // Core Services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(),
  );
  getIt.registerLazySingleton<LocalNotificationsService>(
    () => LocalNotificationsService(),
  );
  getIt.registerLazySingleton<ForegroundPushHandler>(
    () => ForegroundPushHandler(
      pushService: getIt<PushNotificationService>(),
      localNotifications: getIt<LocalNotificationsService>(),
    ),
  );
  getIt.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());

  // Global Auth State
  getIt.registerLazySingleton<AppAuthCubit>(
    () => AppAuthCubit(storageService: getIt<SecureStorageService>()),
  );

  getIt.registerLazySingleton<ApiService>(
    () => ApiService(
      storageService: getIt<SecureStorageService>(),
      appAuthCubit: getIt<AppAuthCubit>(),
      // Pass a provider function here to avoid a circular dependency.
      tokenRefresherProvider: () => getIt<AuthService>(),
    ),
  );

  // Feature Data Services
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(apiService: getIt<ApiService>()),
  );
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(apiService: getIt<ApiService>()),
  );

  // Feature Cubits
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      authService: getIt<AuthService>(),
      storageService: getIt<SecureStorageService>(),
      biometricService: getIt<BiometricService>(),
      appAuthCubit: getIt<AppAuthCubit>(),
      // Re-attach this device's push token to whoever just signed in.
      notificationCubit: getIt<NotificationCubit>(),
    ),
  );

  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(apiService: getIt<ApiService>()),
  );

  // Kept as a singleton because it owns a long-living FCM subscription.
  getIt.registerLazySingleton<NotificationCubit>(
    () => NotificationCubit(
      pushService: getIt<PushNotificationService>(),
      notificationService: getIt<NotificationService>(),
      storageService: getIt<SecureStorageService>(),
      deviceInfoService: getIt<DeviceInfoService>(),
    ),
  );
}
