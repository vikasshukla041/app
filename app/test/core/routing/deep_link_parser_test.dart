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

    test('an id as a query parameter when the route has no :id', () {
      // /dashboard is declared as a plain path, so /dashboard/123 would match
      // nothing. This is the shape the ClickUp task's own example asks for.
      expect(
        DeepLinkParser.parse(<String, String>{
          'route': '/dashboard',
          'id': '123',
        }),
        '/dashboard?id=123',
      );
    });

    test('an id as a path segment when the route declares :id', () {
      expect(
        DeepLinkParser.parse(<String, String>{
          'route': '/alerts',
          'id': 'alert_987',
        }),
        '/alerts/alert_987',
      );
    });

    test('a path id alongside other keys, which stay in the query', () {
      final String? location = DeepLinkParser.parse(<String, String>{
        'route': '/alerts',
        'id': 'alert_987',
        'title': 'Order filled',
      });

      // Asserted through Uri rather than against a literal, so the test pins
      // the behaviour and not Dart's choice of escape for a space.
      final Uri uri = Uri.parse(location!);
      expect(uri.path, '/alerts/alert_987');
      expect(uri.queryParameters['title'], 'Order filled');
      expect(
        uri.queryParameters.containsKey('id'),
        isFalse,
        reason: 'the id moved into the path, so it must not also be a query',
      );
    });

    test('extra payload keys, forwarded as query parameters', () {
      final Uri uri = Uri.parse(
        DeepLinkParser.parse(<String, String>{
          'route': '/dashboard',
          'id': '123',
          'title': 'Order filled',
        })!,
      );

      expect(uri.path, '/dashboard');
      expect(uri.queryParameters['id'], '123');
      expect(uri.queryParameters['title'], 'Order filled');
    });

    test('escapes a query value that would otherwise change the route', () {
      // Why extra keys are safe as query parameters: Uri encodes them, so
      // nothing in a payload can climb out of the route it named.
      final Uri uri = Uri.parse(
        DeepLinkParser.parse(<String, String>{
          'route': '/dashboard',
          'id': '../../login',
        })!,
      );

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

    test(
      'a route already carrying its id, since only the bare path is listed',
      () {
        expect(
          DeepLinkParser.parse(<String, String>{'route': '/alerts/987'}),
          isNull,
        );
      },
    );

    test('an empty payload', () {
      expect(DeepLinkParser.parse(const <String, String>{}), isNull);
    });
  });

  group('rejects an unsafe path id', () {
    // A path segment is pasted into the URL, so unlike a query parameter it
    // has to be checked. Each of these would otherwise reshape the route.
    for (final String id in <String>[
      '../login',
      'a/b',
      '..',
      '.',
      'a?b',
      'a#b',
    ]) {
      test('"$id"', () {
        expect(
          DeepLinkParser.parse(<String, String>{'route': '/alerts', 'id': id}),
          isNull,
        );
      });
    }
  });

  group('rejects a route that needs an id but was not given one', () {
    // /alerts is declared /alerts/:id, so the bare path matches no route.
    // Returning it would strand the tap on the not-found screen.
    test('no id key at all', () {
      expect(
        DeepLinkParser.parse(<String, String>{'route': '/alerts'}),
        isNull,
      );
    });

    test('an empty id', () {
      expect(
        DeepLinkParser.parse(<String, String>{'route': '/alerts', 'id': ''}),
        isNull,
      );
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
