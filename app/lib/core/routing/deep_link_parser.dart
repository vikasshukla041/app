import 'app_routes.dart';

/// turns notification data safe route
abstract final class DeepLinkParser {
  /// route is destination main
  static const String _routeKey = 'route';
  static const String _idKey = 'id';

  static String? parse(Map<String, String> data) {
    final String? route = data[_routeKey];

    if (route == null || !AppRoutes.deepLinkable.contains(route)) {
      return null;
    }

    final String? id = data[_idKey];
    final bool needsId = AppRoutes.idInPath.contains(route);
    final bool idBelongsInPath = needsId && id != null && id.isNotEmpty;

    // A `<path>/:id` route with no id names nothing, so the tap would open nothing.
    if (needsId && !idBelongsInPath) {
      return null;
    }

    if (idBelongsInPath && !_isSafeSegment(id)) {
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

  /// reject anything that comes out of, add to named routes
  static bool _isSafeSegment(String value) =>
      !value.contains('/') &&
      !value.contains('?') &&
      !value.contains('#') &&
      value != '.' &&
      value != '..';
}
