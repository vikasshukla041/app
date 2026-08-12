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

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> show({required String title, required String body}) async {
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
      );
    } catch (e) {
      _log('Show failed: $e');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocalNotificationService] $message');
    }
  }
}
