import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Message-arrival notifications. The mesh foreground service has its own
/// (silent, LOW-importance) channel; this one is HIGH so new messages heads-up.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    // API 33+: notifications need a runtime grant. Ask once at boot — this
    // also unblocks the foreground service's "Mesh active" notification.
    await Permission.notification.request();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    _ready = await _plugin.initialize(
          const InitializationSettings(android: android),
        ) ??
        false;
  }

  Future<void> showMessage({
    required String chatId,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.show(
      chatId.hashCode & 0x7fffffff,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'messages',
          'Messages',
          channelDescription: 'New encrypted messages',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
        ),
      ),
    );
  }
}
