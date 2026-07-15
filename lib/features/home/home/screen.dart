import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';
import '../location/background_credentials.dart';
import '../location/geofence_repository.dart';
import '../location/notification_service.dart';
import '../location/app_settings.dart';
import '../location/push_service.dart';
import '../memories/memories_screen.dart';
import 'settings_screen.dart';
import '../location/map_screen.dart';
import '../location/footprint_screen.dart';
import '../us/us_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  RealtimeChannel? _partnerChannel;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPairing();
  }

  /// 检查当前用户是否已配对
  /// 数据库 schema: couples(user_a, user_b)
  Future<bool> _isPaired() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      final r = await supabase
          .from('couples')
          .select('id')
          .or('user_a.eq.$uid,user_b.eq.$uid')
          .maybeSingle();
      return r != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkPairing() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) context.go('/login');
      return;
    }

    // 检查是否已配对
    final paired = await _isPaired();

    if (!paired) {
      // 未配对，跳转到配对页
      if (mounted) context.go('/pairing');
      return;
    }

    // 已配对，初始化后台服务
    try {
      await refreshBgCredentials();
      await NotificationService.init();
      await PushService.init();

      if (await getBgEnabled()) {
        await BackgroundLocationService().start();
      }

      if (!PushService.fcmReady) {
        _partnerChannel = GeofenceRepository().watchPartnerCheckins();
      }
    } catch (e) {
      // 后台服务初始化失败不阻塞主流程
      debugPrint('后台服务初始化失败（非致命）: $e');
    }
  }

  @override
  void dispose() {
    _partnerChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 错误状态显示
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('吾俩')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('出了点问题', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => setState(() { _error = null; _checkPairing(); }),
                  child: const Text('重试'),
                ),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('退出登录'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('吾俩'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          UsHubScreen(),
          MapScreen(),
          MemoriesScreen(),
          FootprintScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: '我们'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: '位置'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_album_outlined), label: '回忆'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: '足迹'),
        ],
      ),
    );
  }
}
