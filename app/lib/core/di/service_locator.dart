import 'package:get_it/get_it.dart';

import '../../features/auth/auth_cubit.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/data/services/biometric_service.dart';
import '../../features/dashboard/dashboard_cubit.dart';
import '../../features/dashboard/data/services/dashboard_service.dart';
import '../../features/notifications/data/services/device_info_service.dart';
import '../../features/notifications/data/services/foreground_push_handler.dart';
import '../../features/notifications/data/services/local_notifications_service.dart';
import '../../features/notifications/data/services/notification_service.dart';
import '../../features/notifications/data/services/push_notification_service.dart';
import '../../features/notifications/notification_cubit.dart';
import '../auth/app_auth_cubit.dart';
import '../network/api_service.dart';
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
  getIt.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());

  // Global Auth State
  getIt.registerLazySingleton<AppAuthCubit>(
    () => AppAuthCubit(storageService: getIt<SecureStorageService>()),
  );

  // Registered after AppAuthCubit: it drops any push that arrives with no
  // signed-in user, since the device stays subscribed after sign-out.
  getIt.registerLazySingleton<ForegroundPushHandler>(
    () => ForegroundPushHandler(
      pushService: getIt<PushNotificationService>(),
      localNotifications: getIt<LocalNotificationsService>(),
      appAuthCubit: getIt<AppAuthCubit>(),
    ),
  );

  getIt.registerLazySingleton<ApiService>(
    () => ApiService(
      storageService: getIt<SecureStorageService>(),
      appAuthCubit: getIt<AppAuthCubit>(),
      // Pass a provider function here to avoid a circular dependency.
      tokenRefresherProvider: () => getIt<AuthService>(),
    ),
  );

  // Feature Data Services — each is the only caller of its own endpoints.
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(apiService: getIt<ApiService>()),
  );
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(apiService: getIt<ApiService>()),
  );
  getIt.registerLazySingleton<DashboardService>(
    () => DashboardService(apiService: getIt<ApiService>()),
  );

  // Feature Cubits
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      authService: getIt<AuthService>(),
      storageService: getIt<SecureStorageService>(),
      biometricService: getIt<BiometricService>(),
      appAuthCubit: getIt<AppAuthCubit>(),
    ),
  );

  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(dashboardService: getIt<DashboardService>()),
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
