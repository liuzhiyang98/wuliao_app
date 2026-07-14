import 'dart:math';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/local_db.dart';
import '../../core/supabase.dart';

/// 实时精确位置共享服务（MVP 版：App 在前台时持续上报）。
/// 后台持续定位需接入 flutter_background_geolocation（见 README 进阶说明）。
class LocationService {
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<String?> _coupleId() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final r = await supabase
        .from('profiles')
        .select('couple_id')
        .eq('id', uid)
        .single();
    return r['couple_id'];
  }

  /// 开始把自己的位置实时上报到 Supabase（对方可在地图页看到）
  Future<void> startSharing() async {
    if (!await ensurePermission()) return;
    final cid = await _coupleId();
    if (cid == null) return;
    final uid = supabase.auth.currentUser!.id;
    _sub = Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) async {
      await supabase.from('live_locations').upsert({
        'user_id': uid,
        'couple_id': cid,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'sharing': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      await LocalDb.saveLastLocation(pos.latitude, pos.longitude);
      await _maybeAppendHistory(pos.latitude, pos.longitude, pos.accuracy);
    });
  }

  LatLng? _lastHistPos;
  DateTime? _lastHistAt;

  /// 带节流地写入历史轨迹（爱情足迹地图用）：移动超过 15m 或间隔 >30s 才记一笔。
  Future<void> _maybeAppendHistory(double lat, double lng, double acc) async {
    final now = DateTime.now();
    if (_lastHistAt != null && now.difference(_lastHistAt!).inSeconds < 30) return;
    if (_lastHistPos != null) {
      final d = _haversineM(_lastHistPos!.latitude, _lastHistPos!.longitude, lat, lng);
      if (d < 15 && _lastHistAt != null && now.difference(_lastHistAt!).inMinutes < 2) return;
    }
    _lastHistPos = LatLng(lat, lng);
    _lastHistAt = now;
    final cid = await _coupleId();
    if (cid == null) return;
    final uid = supabase.auth.currentUser!.id;
    try {
      await supabase.from('location_history').insert({
        'user_id': uid,
        'couple_id': cid,
        'lat': lat,
        'lng': lng,
        'accuracy': acc,
      });
    } catch (_) {}
  }

  /// 内联 Haversine 距离计算（米），避免 Distance 类 Web 兼容问题
  static double _haversineM(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000; // 地球半径 m
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void stop() => _sub?.cancel();

  /// 每 5 秒拉取一次对方位置（两人私人使用，轮询足够顺滑且稳）
  Stream<List<Map<String, dynamic>>> partnerStream() {
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final cid = await _coupleId();
      if (cid == null) return <Map<String, dynamic>>[];
      final rows = await supabase
          .from('live_locations')
          .select()
          .eq('couple_id', cid)
          .neq('user_id', supabase.auth.currentUser!.id);
      return List<Map<String, dynamic>>.from(rows);
    });
  }
}
