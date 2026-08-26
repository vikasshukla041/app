import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  DeviceInfoService({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<String> deviceName() async {
    try {
      // Use defaultTargetPlatform since dart:io does not exist on web.
      if (kIsWeb) {
        // A browser has no device model, so use the browser and OS name instead.
        final WebBrowserInfo info = await _plugin.webBrowserInfo;
        final String browser = info.browserName.name;
        final String os = info.platform ?? '';
        return os.isEmpty ? browser : '$browser on $os';
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidDeviceInfo info = await _plugin.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IosDeviceInfo info = await _plugin.iosInfo;
        return info.utsname.machine;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceInfoService] Lookup failed: $e');
      }
    }
    return 'Unknown device';
  }
}
