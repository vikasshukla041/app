import 'package:activotrade_app/features/auth/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('parses a well-formed payload', () {
      final User? user = User.fromJson(<String, dynamic>{
        'id': 'user_demo_123',
        'username': 'demo',
        'fullName': 'Demo Investor',
      });

      expect(
        user,
        const User(
          id: 'user_demo_123',
          username: 'demo',
          fullName: 'Demo Investor',
        ),
      );
    });

    test('returns null when a field is missing', () {
      final User? user = User.fromJson(<String, dynamic>{
        'id': 'user_demo_123',
        'username': 'demo',
      });

      expect(user, isNull);
    });

    test('returns null when a field has the wrong type', () {
      final User? user = User.fromJson(<String, dynamic>{
        'id': 1,
        'username': 'demo',
        'fullName': 'Demo Investor',
      });

      expect(user, isNull);
    });

    test('returns null for a non-map payload', () {
      expect(User.fromJson('not a map'), isNull);
      expect(User.fromJson(null), isNull);
    });
  });
}
