import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    _initialized = true;

    // Request permission on Android 13+
    _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showRefreshNotification(String message) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'horizon_refresh',
      'Data Refresh',
      channelDescription: 'Notifications when briefing data is refreshed',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      0,
      'Horizon',
      message,
      const NotificationDetails(android: androidDetails),
    );
  }
}
