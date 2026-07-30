import 'package:activotrade_app/core/network/auth_interceptor.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;
  late AuthInterceptor interceptor;

  setUp(() {
    storage = MockSecureStorageService();
    interceptor = AuthInterceptor(storageService: storage);
  });

  Future<RequestOptions> run() async {
    final RequestOptions options = RequestOptions(path: '/api/user/balance');
    await interceptor.onRequest(options, RequestInterceptorHandler());
    return options;
  }

  test('adds Bearer header when a token is stored', () async {
    when(() => storage.getToken()).thenAnswer((_) async => 'tok_123');

    final RequestOptions options = await run();

    expect(options.headers['Authorization'], 'Bearer tok_123');
  });

  test('adds no header when no token is stored', () async {
    when(() => storage.getToken()).thenAnswer((_) async => null);

    final RequestOptions options = await run();

    expect(options.headers.containsKey('Authorization'), isFalse);
  });

  test('adds no header when the stored token is empty', () async {
    when(() => storage.getToken()).thenAnswer((_) async => '');

    final RequestOptions options = await run();

    expect(options.headers.containsKey('Authorization'), isFalse);
  });
}
