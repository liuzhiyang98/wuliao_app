import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_service.dart';
import '../../core/supabase.dart';

const _storage = FlutterSecureStorage();
const _kFcmReady = 'wuliao.fcm_ready';

/// 后台被杀后由系统投递的 FCM 消息回调（必须是顶层函数）。
/// 通知消息由系统自动弹出；这里再补一次本地通知以统一样式。
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final n = message.notification;
  if (n != null) {
    await NotificationService.init();
    await NotificationService.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: n.title ?? '吾俩',
      body: n.body ?? '',
    );
  }
}

/// 封装 Firebase Cloud Messaging（FCM，免费 Spark 计划）。
///
/// 关键设计：自动报备的「推送」不再依赖 App 存活——
/// 围栏事件写入 `checkins` 后，由 Supabase 数据库 webhook 触发 Edge Function，
/// 经 FCM 把通知下发到伴侣设备（即使 App 被杀、网络在也能收到）。
/// 本类只负责：初始化、要权限、上报 token、把前台消息用本地通知弹出来。
class PushService {
  static bool fcmReady = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      // 前台消息：系统不会自动弹，用本地通知显示
      FirebaseMessaging.onMessage.listen((msg) async {
        final n = msg.notification;
        if (n != null) {
          await NotificationService.init();
          await NotificationService.show(
            id: msg.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
            title: n.title ?? '吾俩',
            body: n.body ?? '',
          );
        }
      });
      // 点击通知启动 App 后的回调（这里暂不需要额外动作）
      FirebaseMessaging.onMessageOpenedApp.listen((_) {});

      final token = await m.getToken();
      if (token != null) {
        await _saveToken(token);
        fcmReady = true;
        await _storage.write(key: _kFcmReady, value: '1');
        // token 可能刷新（重装/换设备），持续同步
        m.onTokenRefresh.listen((t) => _saveToken(t));
      } else {
        await _storage.write(key: _kFcmReady, value: '0');
      }
    } catch (_) {
      // 没配置 Firebase（缺 google-services.json / GoogleService-Info.plist）时优雅降级：
      // 回到 Realtime 监听（仅 App 存活时收通知），fcmReady 保持 false。
      fcmReady = false;
      try {
        await _storage.write(key: _kFcmReady, value: '0');
      } catch (_) {}
    }
  }

  static Future<void> _saveToken(String token) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await supabase
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', uid);
    } catch (_) {}
  }

  /// 后台隔离里判断 FCM 是否已就绪（isolate 间不共享内存，只能读安全存储）。
  static Future<bool> isFcmReady() async {
    try {
      final v = await _storage.read(key: _kFcmReady);
      return v == '1';
    } catch (_) {
      return false;
    }
  }
}
