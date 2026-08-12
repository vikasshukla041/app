import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  DeviceInfoService({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<String> deviceName() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo info = await _plugin.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (Platform.isIOS) {
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
