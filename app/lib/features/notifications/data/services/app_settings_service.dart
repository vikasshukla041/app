import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens the OS page where the user can turn notifications back on.
///
/// A MethodChannel rather than a package: this is two platform calls, and the
/// native side is shorter than the dependency it would replace.
class AppSettingsService {
  /// Lets tests inject a channel; production uses the real one.
  AppSettingsService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'activotrade/app_settings';

  final MethodChannel _channel;

  /// False when nothing opened, so the caller can say so rather than leave the
  /// user looking at a button that did nothing.
  Future<bool> openNotificationSettings() async {
    // No browser lets a page open its own settings, so do not even ask.
    if (kIsWeb) {
      return false;
    }

    try {
      final bool? opened = await _channel.invokeMethod<bool>(
        'openNotificationSettings',
      );
      return opened ?? false;
    } on MissingPluginException {
      // A host with no native side wired up — desktop, or a widget test.
      return false;
    } on PlatformException catch (e) {
      _log('Could not open settings: ${e.code}');
      return false;
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppSettingsService] $message');
    }
  }
}
