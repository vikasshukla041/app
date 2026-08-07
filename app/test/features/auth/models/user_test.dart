import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('parses a well-formed payload', () {
      expect(
        User.fromJson(const <String, dynamic>{
          'id': 'user_demo_123',
          'username': 'demo',
          'fullName': 'Demo Investor',
        }),
        const User(
          id: 'user_demo_123',
          username: 'demo',
          fullname: 'Demo Investor',
        ),
      );
    });

    test('falls back to the username when fullName is missing', () {
      expect(
        User.fromJson(const <String, dynamic>{
          'id': 'user_demo_123',
          'username': 'demo',
        }),
        const User(id: 'user_demo_123', username: 'demo', fullname: 'demo'),
      );
    });

    test('falls back to the username when fullName is blank', () {
      expect(
        User.fromJson(const <String, dynamic>{
          'id': 'user_demo_123',
          'username': 'demo',
          'fullName': '',
        }),
        const User(id: 'user_demo_123', username: 'demo', fullname: 'demo'),
      );
    });

    group('returns null rather than fabricating a user', () {
      test('on an empty map', () {
        expect(User.fromJson(const <String, dynamic>{}), isNull);
      });

      test('when id is missing', () {
        expect(
          User.fromJson(const <String, dynamic>{'username': 'demo'}),
          isNull,
        );
      });

      test('when username is missing', () {
        expect(
          User.fromJson(const <String, dynamic>{'id': 'user_demo_123'}),
          isNull,
        );
      });

      test('when id is blank', () {
        expect(
          User.fromJson(const <String, dynamic>{'id': '', 'username': 'demo'}),
          isNull,
        );
      });

      test('when a field has the wrong type', () {
        expect(
          User.fromJson(const <String, dynamic>{'id': 42, 'username': 'demo'}),
          isNull,
        );
      });

      test('when the payload is not a map at all', () {
        expect(User.fromJson('not a map'), isNull);
        expect(User.fromJson(null), isNull);
      });
    });
  });
}
