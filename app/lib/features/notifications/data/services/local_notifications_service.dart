import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Draw a notification while the app is in the foreground
class LocalNotificationsService {
  LocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Android 8+ refuses a heads-up banner unless channel registered important.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'activotrade_alerts',
    'ActivoTrade Alerts',
    description: 'Market moves, order executions and account security notices',
    importance: Importance.high,
  );

  Future<void>? _initialisation;

  /// Notification ids need to be unique among other
  int _nextId = 0;

  /// Stream of taps on banners this class drew; broadcast so no taps get lost.
  final StreamController<Map<String, String>> _taps =
      StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get onTap => _taps.stream;

  /// one initialisation rather than re-registring
  Future<void> init() => _initialisation ??= _initialise();

  Future<void> _initialise() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// The plugin hands back the payload string [show] was given, so the FCM
  /// data map makes the round trip as JSON.
  void _onTap(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty || _taps.isClosed) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is! Map) {
        return;
      }
      _taps.add(<String, String>{
        for (final MapEntry<dynamic, dynamic> entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      });
    } on FormatException catch (e) {
      // Should never happen, but do not let a bad payload crash the app.
      _log('Tap payload was not valid JSON: $e');
    }
  }

  Future<void> show({
    required String title,
    required String body,
    Map<String, String> payload = const <String, String>{},
  }) async {
    try {
      await _plugin.show(
        id: _nextId++,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload.isEmpty ? null : jsonEncode(payload),
      );
    } catch (e) {
      _log('Show failed: $e');
    }
  }

  /// Only reached in tests — this service lives for the whole process.
  Future<void> dispose() => _taps.close();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocalNotificationsService] $message');
    }
  }
}
