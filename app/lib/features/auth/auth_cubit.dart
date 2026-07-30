import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_service.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_state.dart';

/// Owns the login business logic. UI never talks to Dio or storage directly.
///
/// Dependencies are constructor-injected with production defaults, so
/// tests can substitute mocks without any framework.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({ApiService? apiService, SecureStorageService? storageService})
    : _apiService = apiService ?? ApiService(),
      _storageService = storageService ?? SecureStorageService(),
      super(const AuthInitial());

  final ApiService _apiService;
  final SecureStorageService _storageService;

  /// Emits [AuthLoading], then [AuthSuccess] only after the token is
  /// persisted, or [AuthFailure] with a reason the UI can localize.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    // Ignore re-entry while a request is in flight: UI guards can be
    // bypassed (keyboard submit, future call sites), this one cannot.
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      final Response<dynamic> response = await _apiService.login(
        username: username,
        password: password,
      );

      final String? token = _extractToken(response.data);
      if (token == null) {
        if (kDebugMode) {
          debugPrint('Login failed: response contained no usable token.');
        }
        emit(const AuthFailure(AuthFailureReason.generic));
        return;
      }

      // Persist before emitting success: the UI navigates on AuthSuccess,
      // and a dashboard without a stored token would fail every request.
      await _storageService.saveToken(token);
      emit(const AuthSuccess());
    } on DioException catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Login failed: ${e.type} ${e.message}');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(AuthFailure(_mapDioError(e)));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Login failed: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(const AuthFailure(AuthFailureReason.generic));
    }
  }

  /// Defensive extraction — never assumes the response shape.
  String? _extractToken(dynamic data) {
    if (data case {'token': final String token} when token.isNotEmpty) {
      return token;
    }
    return null;
  }

  /// Maps transport-level errors to a failure reason. The UI layer turns
  /// the reason into a localized message — raw text never lives here.
  AuthFailureReason _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthFailureReason.network;
      case DioExceptionType.badResponse:
        return switch (e.response?.statusCode) {
          401 => AuthFailureReason.credentials,
          429 => AuthFailureReason.tooManyAttempts,
          500 => AuthFailureReason.serverUnavailable,
          _ => AuthFailureReason.generic,
        };
      default:
        return AuthFailureReason.generic;
    }
  }
}
