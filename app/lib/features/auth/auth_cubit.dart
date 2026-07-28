import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_service.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_state.dart';

/// Handles all authentication business logic
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({ApiService? apiService, SecureStorageService? storageService})
    : _apiService = apiService ?? ApiService(),
      _storageService = storageService ?? SecureStorageService(),
      super(const AuthInitial());

  final ApiService _apiService;
  final SecureStorageService _storageService;

  static const String _networkError =
      'Unable to connect to server.\nPlease check your network connection.';

  static const String _credentialError = 'Invalid username or password.';

  static const String _genericError =
      'Something went wrong. Please try again later.';

  /// Calls login API and emits state
  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      final Response response = await _apiService.login(
        username: username,
        password: password,
      );

      if (response.statusCode != 200) {
        emit(const AuthFailure(_credentialError));
        return;
      }

      final String? token = _extractToken(response.data);

      if (token == null) {
        debugPrint('Login failed: response contained no usable token');

        emit(const AuthFailure(_genericError));
        return;
      }

      await _storageService.saveToken(token);

      emit(const AuthSuccess());
    } on DioException catch (e, stackTrace) {
      debugPrint('Login failed: ${e.type} ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      emit(AuthFailure(_mapDioError(e)));
    } catch (e, stackTrace) {
      debugPrint('Login failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(const AuthFailure(_genericError));
    }
  }

  /// Extract token safely from API response
  String? _extractToken(dynamic data) {
    if (data case {'token': final String token} when token.isNotEmpty) {
      return token;
    }

    return null;
  }

  /// Maps Dio errors to user-friendly messages
  String _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _networkError;

      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 401:
            return _credentialError;

          case 429:
            return 'Too many login attempts. Please try again later.';

          case 500:
            return 'Server is currently unavailable.';

          default:
            return _genericError;
        }

      default:
        return _genericError;
    }
  }
}

