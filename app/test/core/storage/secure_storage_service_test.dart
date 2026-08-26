import 'dart:convert';

import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Storage owns the encoding, so these tests pin the one behaviour the Cubits
/// above it rely on: a blob that no longer parses reads back as null instead
/// of throwing at app launch.
void main() {
  late MockFlutterSecureStorage storage;
  late SecureStorageService service;

  const User user = User(
    id: 'user_demo_123',
    username: 'demo',
    fullname: 'Demo Investor',
  );

  setUp(() {
    storage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: storage);
  });

  void stubRead(String? value) {
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => value);
  }

  group('saveUser', () {
    test('encodes the user so callers never do it themselves', () async {
      when(
        () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      await service.saveUser(user);

      final List<dynamic> captured = verify(
        () => storage.write(
          key: 'auth_user',
          value: captureAny(named: 'value'),
        ),
      ).captured;

      expect(jsonDecode(captured.single as String), <String, dynamic>{
        'id': 'user_demo_123',
        'username': 'demo',
        'fullName': 'Demo Investor',
      });
    });
  });

  group('getUser', () {
    test('round-trips a user written by saveUser', () async {
      stubRead(jsonEncode(user.toJson()));

      expect(await service.getUser(), user);
    });

    test('returns null when nothing has been stored', () async {
      stubRead(null);

      expect(await service.getUser(), isNull);
    });

    test('returns null for a stored blob that is not valid JSON', () async {
      stubRead('not json at all');

      expect(await service.getUser(), isNull);
    });

    test('returns null when the JSON is missing required fields', () async {
      stubRead('{"broken": true}');

      expect(await service.getUser(), isNull);
    });
  });
}
