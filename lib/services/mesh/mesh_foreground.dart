import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process alive (and therefore the mesh sockets, discovery
/// beacon, and relaying) while backgrounded, via an Android foreground
/// service with a persistent "Mesh active" notification.
///
/// The mesh itself runs in the main isolate; the service's task handler is
/// just a heartbeat that holds foreground priority + wake/wifi locks.
abstract final class MeshForeground {
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'messy_mesh',
        channelName: 'Mesh service',
        channelDescription:
            'Keeps Messy connected to nearby devices and relaying messages',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  static Future<void> start() async {
    init();
    // The persistent notification needs POST_NOTIFICATIONS on API 33+.
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (await isRunning) return;
    await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.connectedDevice],
      serviceId: 471,
      notificationTitle: 'Mesh active',
      notificationText:
          'Connected to nearby devices · relaying encrypted messages',
      callback: meshForegroundCallback,
    );
  }

  static Future<void> stop() => FlutterForegroundTask.stopService();
}

@pragma('vm:entry-point')
void meshForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());
}

class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat only — the mesh lives in the main isolate.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
