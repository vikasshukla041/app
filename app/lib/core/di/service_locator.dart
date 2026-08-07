import 'package:get_it/get_it.dart';

import '../../features/auth/auth_cubit.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/dashboard/dashboard_cubit.dart';
import '../auth/app_auth_cubit.dart';
import '../network/api_service.dart';
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

  // Global Auth State
  getIt.registerLazySingleton<AppAuthCubit>(
    () => AppAuthCubit(storageService: getIt<SecureStorageService>()),
  );

  getIt.registerLazySingleton<ApiService>(
    () => ApiService(
      storageService: getIt<SecureStorageService>(),
      appAuthCubit: getIt<AppAuthCubit>(),
      // Provider, not instance: AuthService needs ApiService, which is what
      // is being registered here. Resolving lazily breaks the cycle.
      tokenRefresherProvider: () => getIt<AuthService>(),
    ),
  );

  // Feature Data Services
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(apiService: getIt<ApiService>()),
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
    () => DashboardCubit(apiService: getIt<ApiService>()),
  );
}
