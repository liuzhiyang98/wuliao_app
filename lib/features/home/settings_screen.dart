import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';
import '../location/app_settings.dart';
import '../location/background_credentials.dart';
import '../location/background_location_service.dart';
import '../location/geofence_repository.dart';
import '../location/notification_service.dart';

/// 设置：后台持续定位、自动报备、位置共享暂停、地点管理。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = GeofenceRepository();
  bool _bg = false;
  bool _auto = false;
  bool _sharing = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _bg = await getBgEnabled();
    _auto = await getAutoEnabled();
    try {
      final uid = supabase.auth.currentUser!.id;
      final r = await supabase
          .from('live_locations')
          .select('sharing')
          .eq('user_id', uid)
          .maybeSingle();
      _sharing = r == null ? true : (r['sharing'] == true);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _applyBg(bool v) async {
    setState(() => _busy = true);
    await setBgEnabled(v);
    await refreshBgCredentials();
    if (v) {
      await BackgroundLocationService().start();
    } else {
      await BackgroundLocationService().stop();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _applyAuto(bool v) async {
    setState(() => _busy = true);
    await setAutoEnabled(v);
    // 重新注册围栏：关掉就移除，打开就加上
    if (await getBgEnabled()) {
      await BackgroundLocationService().stop();
      await BackgroundLocationService().start();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggleSharing(bool v) async {
    setState(() => _sharing = v);
    try {
      final uid = supabase.auth.currentUser!.id;
      await supabase
          .from('live_locations')
          .update({'sharing': v}).eq('user_id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(v ? '已恢复位置共享' : '已暂停位置共享（对方将看不到你）'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('操作失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('后台持续定位'),
            subtitle: const Text('退到后台 / 锁屏也能实时看到彼此'),
            value: _bg,
            onChanged: _busy ? null : _applyBg,
          ),
          SwitchListTile(
            title: const Text('自动报备'),
            subtitle: const Text('到家 / 出门自动给对方发提醒'),
            value: _auto,
            onChanged: _busy ? null : _applyAuto,
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('管理报备地点'),
            subtitle: const Text('家 / 公司 / 自定义'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/geofences'),
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('位置共享'),
            subtitle: const Text('随手暂停，把掌控权交回自己'),
            value: _sharing,
            onChanged: _toggleSharing,
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '信任优先：任何时候你都能暂停共享、关闭后台定位、或解绑即删。'
                '我们不会收集 App 使用记录、屏幕解锁等越界数据。',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
