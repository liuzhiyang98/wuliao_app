import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';
import 'background_credentials.dart';
import 'notification_service.dart';
import 'place_emoji.dart';

/// 地理围栏（自动报备地点）的前台仓储 + 伴侣实时报备监听。
/// 数据库 schema: geofences(id, couple_id, name, latitude, longitude, radius_meters,
///   icon, enabled, created_by, created_at)
class GeofenceRepository {
  Future<String?> _coupleId() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    // 通过 couples 表查询 couple_id
    final r = await supabase
        .from('couples')
        .select('id')
        .or('user_a.eq.$uid,user_b.eq.$uid')
        .eq('status', 'active')
        .maybeSingle();
    return r?['id'];
  }

  Future<List<Map<String, dynamic>>> list() async {
    final uid = supabase.auth.currentUser!.id;
    // 数据库用 created_by 而不是 owner_id
    final rows = await supabase
        .from('geofences')
        .select()
        .eq('created_by', uid)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> add({
    required String name,
    required double lat,
    required double lng,
    required double radiusM,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final cid = await _coupleId();
    // 字段名: radius_meters (不是 radius_m), created_by (不是 owner_id)
    await supabase.from('geofences').insert({
      'couple_id': cid,
      'name': name,
      'latitude': lat,
      'longitude': lng,
      'radius_meters': radiusM.toInt(),
      'icon': 'home',
      'enabled': true,
      'created_by': uid,
    });
    await refreshBgCredentials();
  }

  Future<void> remove(String id) async {
    await supabase.from('geofences').delete().eq('id', id);
  }

  /// 监听伴侣的自动报备事件
  RealtimeChannel watchPartnerCheckins() {
    final uid = supabase.auth.currentUser!.id;
    final channel = supabase.channel('checkins_$uid');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'checkins',
      callback: (payload) {
        final row = payload.newRecord;
        if (row['user_id'] == uid) return; // 忽略自己的
        final name = (row['place_name'] as String?) ?? (row['geofence_id'] ?? '某个地点');
        final isEnter = row['event_type'] == 'arrived' || row['event_type'] == 'enter';
        final emoji = placeEmoji(name is String ? name : '');
        final title = isEnter ? '$emoji 自动报备' : '🚪 自动报备';
        final body = isEnter ? 'Ta 到了$name' : 'Ta 离开了$name';
        NotificationService.show(
          id: (row['id'] ?? name).hashCode,
          title: title,
          body: body,
        );
      },
    );
    channel.subscribe();
    return channel;
  }
}
