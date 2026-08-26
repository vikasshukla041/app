import 'app_routes.dart';

/// Turns a push notification's data into a safe route, or null if invalid.
abstract final class DeepLinkParser {
  /// 'route' is the destination; every other key travels with it.
  static const String _routeKey = 'route';

  /// Returns null for bad data instead of throwing, since this is untrusted
  /// input. A payload with no route is the normal case, not an error.
  ///
  /// `{'route': '/dashboard', 'id': '1'}` becomes `/dashboard?id=1`.
  ///
  /// Every extra key becomes a query parameter, and `Uri` escapes them, so no
  /// payload value can break out of the route it named. If a route with a path
  /// parameter (`/thing/:id`) is added later, that id must be validated before
  /// it is pasted into the path — a query parameter needs no such check.
  static String? parse(Map<String, String> data) {
    final String? route = data[_routeKey];
    if (route == null || !AppRoutes.deepLinkable.contains(route)) {
      return null;
    }

    final Map<String, String> query = <String, String>{
      for (final MapEntry<String, String> entry in data.entries)
        if (entry.key != _routeKey && entry.value.isNotEmpty)
          entry.key: entry.value,
    };

    return Uri(
      path: route,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}
