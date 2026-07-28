# Changes Made

## 1. `app/lib/core/constants/api_constants.dart`

Changed `baseUrl` from the Android-emulator alias (`10.0.2.2`) to `localhost`, since the app is currently being run as a native Windows desktop app, not on an Android emulator. `10.0.2.2` only resolves on an Android emulator; on Windows/Chrome it must be `localhost`.

```dart
/// Central place for every API-related constant.
///
/// `10.0.2.2` is the Android emulator's alias for the host machine's
/// `localhost`, where the mock API listens on port 3000.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:3000';

  static const String login = '/api/auth/login';
  static const String balance = '/api/user/balance';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
```

> If you switch to running on an Android emulator again, change `baseUrl` back to `http://10.0.2.2:3000`.

---

## 2. `app/android/gradle.properties`

Lowered the Gradle JVM heap from `-Xmx8G` to `-Xmx1536M`. The original value requested 8GB of heap for the Gradle daemon alone, which exceeded the machine's total RAM (~7.8GB) and crashed the build with an out-of-memory error every time. This only matters for Android builds (Gradle), not the Windows desktop build.

```properties
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
# This newDsl flag was added by the Flutter template
android.newDsl=false
# This builtInKotlin flag was added by the Flutter template
android.builtInKotlin=false
```

---

## 3. `C:\Users\VIKAS SHUKLA\.android\avd\Pixel_9.avd\config.ini` (outside the repo)

Fixed a stale `skin.path` left over from an older Android SDK install location, which caused the emulator to fail immediately with `unknown skin name 'pixel_9'`.

```ini
skin.path=C:\Android\Sdk\skins\pixel_9
```

(Previously pointed to `C:\Users\VIKAS SHUKLA\AppData\Local\Android\Sdk\skins\pixel_9`, which no longer exists — the SDK now lives at `C:\Android\Sdk`.)

---

## Other machine-level (non-code) fixes along the way

- Enabled Windows **Developer Mode** (required for Flutter's plugin symlinks).
- Set `ANDROID_HOME` / `ANDROID_SDK_ROOT` to `C:\Android\Sdk` (already done at the user env-var level; just needed a fresh terminal to pick it up).
- Installed the missing **C++ ATL for latest v143 build tools** component via Visual Studio Installer — required by the `flutter_secure_storage_windows` plugin's native build, was causing `atlstr.h` not found.

---

# Full `lib/` Folder Contents

Complete current contents of every file under `app/lib/`, for reference.

## `lib/main.dart`

```dart
import 'package:flutter/material.dart';

import 'features/auth/auth_screen.dart';

void main() {
  runApp(const ActivoTradeApp());
}

class ActivoTradeApp extends StatelessWidget {
  const ActivoTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ActivoTrade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
```

## `lib/core/constants/api_constants.dart`

```dart
/// Central place for every API-related constant.
///
/// `10.0.2.2` is the Android emulator's alias for the host machine's
/// `localhost`, where the mock API listens on port 3000.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:3000';

  static const String login = '/api/auth/login';
  static const String balance = '/api/user/balance';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
```

## `lib/core/network/api_service.dart`

```dart
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

/// Single gateway to the backend. No UI code, no navigation, no SnackBars.
///
/// The [Dio] instance is injectable so tests can pass a mocked client.
class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
              ),
            );

  final Dio _dio;

  /// POST /api/auth/login — authenticates with username + password.
  Future<Response<dynamic>> login({
    required String username,
    required String password,
  }) {
    return _dio.post<dynamic>(
      ApiConstants.login,
      data: <String, dynamic>{
        'username': username,
        'password': password,
      },
    );
  }
}
```

## `lib/core/security/secure_storage_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage (iOS Keychain / Android Keystore).
///
/// Only this class knows how and where the token is stored; the rest of
/// the app depends on these three methods.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
```

## `lib/features/auth/auth_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../dashboard/dashboard_screen.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'widgets/login_form.dart';

/// Assembly only: provides the cubit, reacts to navigation/error states,
/// and lays out the form. All logic lives in [AuthCubit].
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => AuthCubit(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (BuildContext context, AuthState state) {
                  if (state is AuthSuccess) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (BuildContext context, AuthState state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'ActivoTrade',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 32),
                      const LoginForm(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## `lib/features/auth/auth_state.dart`

```dart
import 'package:equatable/equatable.dart';

/// All possible states of the authentication flow.
///
/// `sealed` lets the compiler guarantee every state is handled.
/// Equatable gives value-equality, so emitting an identical state
/// does not trigger a redundant UI rebuild.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => <Object?>[];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
```

## `lib/features/auth/auth_cubit.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_service.dart';
import '../../core/security/secure_storage_service.dart';
import 'auth_state.dart';

/// Owns the login business logic. UI never talks to Dio or storage directly.
///
/// Dependencies are constructor-injected with production defaults, so
/// tests can substitute mocks without any framework.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    ApiService? apiService,
    SecureStorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? SecureStorageService(),
        super(const AuthInitial());

  final ApiService _apiService;
  final SecureStorageService _storageService;

  static const String _networkError =
      'Unable to connect to server.\nPlease check your network connection.';
  static const String _credentialsError = 'Invalid username or password.';
  static const String _genericError =
      'Something went wrong. Please try again later.';

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      final Response<dynamic> response = await _apiService.login(
        username: username,
        password: password,
      );

      final String? token = _extractToken(response.data);
      if (token == null) {
        debugPrint('Login failed: response contained no usable token.');
        emit(const AuthFailure(_genericError));
        return;
      }

      await _storageService.saveToken(token);
      emit(const AuthSuccess());
    } on DioException catch (e) {
      debugPrint('Login failed: ${e.type} ${e.message}');
      emit(AuthFailure(_mapDioError(e)));
    } catch (e) {
      debugPrint('Login failed: $e');
      emit(const AuthFailure(_genericError));
    }
  }

  /// Defensive extraction — never assumes the response shape.
  String? _extractToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic token = data['token'];
      if (token is String && token.isNotEmpty) {
        return token;
      }
    }
    return null;
  }

  /// Maps transport-level errors to user-friendly messages.
  /// Raw exceptions must never reach the UI.
  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _networkError;
      case DioExceptionType.badResponse:
        return _credentialsError;
      default:
        return _genericError;
    }
  }
}
```

## `lib/features/auth/widgets/login_form.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth_cubit.dart';
import '../auth_state.dart';
import 'login_button.dart';
import 'password_text_field.dart';
import 'username_text_field.dart';

/// Assembles the login inputs and forwards user intent to [AuthCubit].
///
/// Stateful only because TextEditingControllers must be disposed.
/// Contains zero business logic.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    context.read<AuthCubit>().login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final bool isLoading = state is AuthLoading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UsernameTextField(
              controller: _usernameController,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            PasswordTextField(
              controller: _passwordController,
              enabled: !isLoading,
            ),
            const SizedBox(height: 24),
            LoginButton(
              onPressed: _onLoginPressed,
              isLoading: isLoading,
            ),
          ],
        );
      },
    );
  }
}
```

## `lib/features/auth/widgets/login_button.dart`

```dart
import 'package:flutter/material.dart';

/// Submit button that disables itself and shows a spinner while loading,
/// preventing duplicate login requests.
class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  static const double _height = 48;
  static const double _spinnerSize = 24;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sign in button',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: _height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: _spinnerSize,
                  height: _spinnerSize,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign In'),
        ),
      ),
    );
  }
}
```

## `lib/features/auth/widgets/password_text_field.dart`

```dart
import 'package:flutter/material.dart';

/// Collects the password. Input only — no logic, no API calls.
class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Password input field',
      textField: true,
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock_outline),
        ),
      ),
    );
  }
}
```

## `lib/features/auth/widgets/username_text_field.dart`

```dart
import 'package:flutter/material.dart';

/// Collects the username. Input only — no logic, no API calls.
class UsernameTextField extends StatelessWidget {
  const UsernameTextField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Username input field',
      textField: true,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Username',
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
    );
  }
}
```

## `lib/features/dashboard/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';

/// Placeholder landing screen after a successful login.
/// Will grow its own cubit/state/widgets in a later step.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: Text(
          'Welcome to ActivoTrade',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
```
