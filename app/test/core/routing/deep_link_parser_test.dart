import 'package:activotrade_app/core/routing/deep_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('accepts', () {
    test('a whitelisted route on its own', () {
      expect(
        DeepLinkParser.parse(<String, String>{'route': '/dashboard'}),
        '/dashboard',
      );
    });

    test('an id, carried as a query parameter', () {
      expect(
        DeepLinkParser.parse(<String, String>{
          'route': '/dashboard',
          'id': '123',
        }),
        '/dashboard?id=123',
      );
    });

    test('extra payload keys, forwarded as query parameters', () {
      final String? location = DeepLinkParser.parse(<String, String>{
        'route': '/dashboard',
        'id': '123',
        'title': 'Order filled',
      });

      // Asserted through Uri rather than against a literal, so the test pins
      // the behaviour and not Dart's choice of escape for a space.
      final Uri uri = Uri.parse(location!);
      expect(uri.path, '/dashboard');
      expect(uri.queryParameters['id'], '123');
      expect(uri.queryParameters['title'], 'Order filled');
    });

    test('the alerts route, with its id as a query parameter', () {
      // The alert id deliberately does not live in the path. A path parameter
      // would have to be validated before being pasted in; a query parameter
      // is escaped by Uri and needs no such check.
      final String? location = DeepLinkParser.parse(<String, String>{
        'route': '/alerts',
        'id': 'alert_987',
        'title': 'Order filled',
      });

      final Uri uri = Uri.parse(location!);
      expect(uri.path, '/alerts');
      expect(uri.queryParameters['id'], 'alert_987');
      expect(uri.queryParameters['title'], 'Order filled');
    });

    test('escapes a value that would otherwise change the route', () {
      // The whole reason extra keys are safe as query parameters: Uri encodes
      // them, so nothing in a payload can climb out of the route it named.
      final String? location = DeepLinkParser.parse(<String, String>{
        'route': '/dashboard',
        'id': '../../login',
      });

      final Uri uri = Uri.parse(location!);
      expect(uri.path, '/dashboard');
      expect(uri.queryParameters['id'], '../../login');
    });
  });

  group('rejects', () {
    test('a payload with no route at all', () {
      // The ordinary case: most notifications carry no deep link, and that is
      // not an error — the app simply opens where it normally would.
      expect(DeepLinkParser.parse(<String, String>{'id': '123'}), isNull);
    });

    test('a route that is not on the whitelist', () {
      expect(
        DeepLinkParser.parse(<String, String>{'route': '/login'}),
        isNull,
        reason: 'a payload must not be able to name a pre-auth screen',
      );
    });

    test('an unknown route', () {
      expect(
        DeepLinkParser.parse(<String, String>{'route': '/admin/users'}),
        isNull,
      );
    });

    test('an alert id smuggled into the path instead of a query', () {
      // '/alerts/987' is not on the whitelist; only the bare path is. This is
      // what stops a payload inventing route shapes the router never declared.
      expect(
        DeepLinkParser.parse(<String, String>{'route': '/alerts/987'}),
        isNull,
      );
    });

    test('an empty payload', () {
      expect(DeepLinkParser.parse(const <String, String>{}), isNull);
    });
  });

  group('ignores', () {
    test('empty values, so they do not become blank query parameters', () {
      expect(
        DeepLinkParser.parse(<String, String>{'route': '/dashboard', 'id': ''}),
        '/dashboard',
      );
    });
  });
}
