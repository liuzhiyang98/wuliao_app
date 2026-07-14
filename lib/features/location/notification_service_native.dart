import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 统一的本地通知封装（前台与后台隔离中都用得到）。
/// 注意：自动报备的「推送」靠它弹出系统通知；
/// 伴侣端在 App 存活（前台/后台）时通过 Supabase Realtime 收到后也用本服务弹通知。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String channelId = 'wuliao_auto';
  static const String channelName = '自动报备';
  static const String channelDesc = '到家 / 出门自动报备提醒';

  /// 在任意 isolate 中调用都是安全的（重复调用无害）。
  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
