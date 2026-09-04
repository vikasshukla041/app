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

  /// Saves a route without telling the router.
  ///
  /// Called from inside the redirect itself, where notifying would re-enter
  /// the redirect that is still running. The redirect it was called from
  /// returns the auth gate, and the state change that later opens the gate
  /// runs it again — which is when this gets consumed.
  void hold(String location) {
    _pending = location;
  }

  /// Returns the pending route and clears it so it is not opened twice.
  String? consume() {
    final String? location = _pending;
    _pending = null;
    return location;
  }
}
