import 'app_routes.dart';

/// Turns a push notification's data into a safe route, or null if invalid.
abstract final class DeepLinkParser {
  /// 'route' is the destination; every other key travels with it.
  static const String _routeKey = 'route';
  static const String _idKey = 'id';

  /// Returns null for bad data instead of throwing, since this is untrusted
  /// input. A payload with no route is the normal case, not an error.
  ///
  /// `{'route': '/dashboard', 'id': '1'}` becomes `/dashboard?id=1`, while
  /// `{'route': '/alerts', 'id': '1'}` becomes `/alerts/1` — the difference is
  /// [AppRoutes.idInPath], which lists the routes declared as `<path>/:id`.
  ///
  /// A path segment is pasted into the URL, so it is validated first. A query
  /// parameter is escaped by [Uri] and needs no such check.
  static String? parse(Map<String, String> data) {
    final String? route = data[_routeKey];
    if (route == null || !AppRoutes.deepLinkable.contains(route)) {
      return null;
    }

    final String? id = data[_idKey];
    final bool needsId = AppRoutes.idInPath.contains(route);
    final bool idBelongsInPath = needsId && id != null && id.isNotEmpty;

    if (needsId && !idBelongsInPath) {
      // The route is declared `<path>/:id`, so without an id it names nothing.
      // Returning the bare path would resolve to no route at all.
      return null;
    }

    if (idBelongsInPath && !_isSafeSegment(id)) {
      // A payload that tried to reshape the route it named.
      return null;
    }

    final Map<String, String> query = <String, String>{
      for (final MapEntry<String, String> entry in data.entries)
        if (entry.key != _routeKey &&
            entry.value.isNotEmpty &&
            !(idBelongsInPath && entry.key == _idKey))
          entry.key: entry.value,
    };

    return Uri(
      path: idBelongsInPath ? '$route/$id' : route,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// Rejects anything that would climb out of, or add to, the named route.
  static bool _isSafeSegment(String value) =>
      !value.contains('/') &&
      !value.contains('?') &&
      !value.contains('#') &&
      value != '.' &&
      value != '..';
}
