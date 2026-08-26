import 'package:flutter/foundation.dart';

/// Holds a route from a notification tap until it is safe for the router to open it.
class DeepLinkController extends ChangeNotifier {
  String? _pending;

  /// True if a notification route is waiting to be opened.
  bool get hasPending => _pending != null;

  /// Saves a route and tells the router to check it; a newer tap replaces an older one.
  void push(String location) {
    _pending = location;
    notifyListeners();
  }

  /// Returns the pending route and clears it so it is not opened twice.
  String? consume() {
    final String? location = _pending;
    _pending = null;
    return location;
  }
}
