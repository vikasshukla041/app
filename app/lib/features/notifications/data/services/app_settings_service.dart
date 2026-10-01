import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// opens the OS page where user can turn notification enable
class AppSettingsService {
  AppSettingsService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'activotrade/app_settings';

  final MethodChannel _channel;

  Future<bool> openNotificationSettings() async {
    // no browser lets a page open its own settings
    if (kIsWeb) {
      return false;
    }

    try {
      final bool? opened = await _channel.invokeMethod<bool>(
        'openNotificationSettings',
      );
      return opened ?? false;
    } on MissingPluginException {
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
