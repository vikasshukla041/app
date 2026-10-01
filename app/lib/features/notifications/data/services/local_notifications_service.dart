import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Draws a notification while the app is in the foreground.
class LocalNotificationsService {
  LocalNotificationsService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Android 8+ refuses a heads-up banner unless the channel is important.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'activotrade_alerts',
    'ActivoTrade Alerts',
    description: 'Market moves, order executions and account security notices',
    importance: Importance.high,
  );

  Future<void>? _initialisation;

  /// Notification IDs need to be unique.
  int _nextId = 0;

  /// Emits payload data whenever one of our local notifications is tapped.
  ///
  /// Broadcast because FF owns the subscription and the
  /// service itself may also be used by tests.
  final StreamController<Map<String, String>> _taps =
      StreamController<Map<String, String>>.broadcast();

  /// Stream of local-notification taps.
  Stream<Map<String, String>> get onTap => _taps.stream;

  /// Initializes the plugin once.
  Future<void> init() => _initialisation ??= _initialise();

  Future<void> _initialise() async {
    if (kIsWeb) {
      return;
    }
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

  /// Receives a tap from flutter_local_notifications.
  ///
  /// The payload was encoded as JSON by [show].
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

      final Map<String, String> data = <String, String>{
        for (final MapEntry<dynamic, dynamic> entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };

      if (data.isEmpty) {
        return;
      }

      _taps.add(data);
    } on FormatException catch (e) {
      // Bad notification payload must never crash the application.
      _log('Tap payload was not valid JSON: $e');
    } catch (e) {
      _log('Could not process notification tap: $e');
    }
  }

  /// Shows a foreground notification.
  ///
  /// [payload] is optional so all existing callers that only provide title
  /// and body continue to work.
  Future<void> show({
    required String title,
    required String body,
    Map<String, String> payload = const <String, String>{},
  }) async {
    //----------
    if (kIsWeb) {
      return;
    }
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

  /// Only used by tests / application shutdown.
  Future<void> dispose() async {
    await _taps.close();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocalNotificationsService] $message');
    }
  }
}
