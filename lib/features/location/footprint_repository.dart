import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

/// 爱情足迹地图的数据仓储。
/// 数据库 schema:
///   location_history: (id, user_id, latitude, longitude, recorded_at) - 没有 couple_id!
///   memories: (id, couple_id, created_by, title, description, image_urls[], memory_date,
///              latitude, longitude, location_name, created_at)
///   geofences: (id, couple_id, name, latitude, longitude, radius_meters, ...)
class FootprintRepository {
  Future<String?> _coupleId() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final r = await supabase
        .from('couples')
        .select('id')
        .or('user_a.eq.$uid,user_b.eq.$uid')
        .eq('status', 'active')
        .maybeSingle();
    return r?['id'];
  }

  Future<List<Map<String, dynamic>>> history({int days = 30}) async {
    final cid = await _coupleId();
    if (cid == null) return [];
    
    // 获取情侣双方 ID
    final couple = await supabase.from('couples').select('user_a, user_b').eq('id', cid).maybeSingle();
    if (couple == null) return [];

    final since = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .toIso8601String();
    
    // location_history 没有 couple_id，用 user_id 过滤
    // 字段名：latitude/longitude (不是 lat/lng)，recorded_at (不是 created_at)
    final rows = await supabase
        .from('location_history')
        .select('user_id, latitude, longitude, recorded_at')
        .or('user_id.eq.${couple['user_a']},user_id.eq.${couple['user_b']}')
        .gte('recorded_at', since)
        .order('recorded_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> memoriesWithLocation() async {
    final cid = await _coupleId();
    if (cid == null) return [];
    final rows = await supabase
        .from('memories')
        .select('id, title, description, latitude, longitude, created_at')
        .eq('couple_id', cid);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.where((m) => m['latitude'] != null && m['longitude'] != null).toList();
  }

  Future<List<Map<String, dynamic>>> geofences() async {
    // 字段名：latitude/longitude/radius_meters (不是 radius_m)
    final rows = await supabase
        .from('geofences')
        .select('name, latitude, longitude, radius_meters');
    return List<Map<String, dynamic>>.from(rows);
  }
}
