import 'package:flutter/foundation.dart';

/// hold routes notificationTap until safe
class DeepLinkController extends ChangeNotifier {
  String? _pending;

  bool get hasPending => _pending != null;

  /// records a location and wakes the router
  void push(String location) {
    _pending = location;
    notifyListeners();
  }

  void hold(String location) {
    _pending = location;
  }

  String? consume() {
    final String? location = _pending;
    _pending = null;
    return location;
  }
}
