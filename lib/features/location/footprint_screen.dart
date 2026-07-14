import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'footprint_repository.dart';

/// 爱情足迹地图：把两人历史位置绘制成轨迹折线，
/// 叠加「回忆点」（带坐标的回忆）与「地点」（自动报备围栏）。
class FootprintScreen extends StatefulWidget {
  const FootprintScreen({super.key});

  @override
  State<FootprintScreen> createState() => _FootprintScreenState();
}

class _FootprintScreenState extends State<FootprintScreen> {
  final _repo = FootprintRepository();
  int _days = 30;
  bool _loading = true;
  String? _error;
  List<Polyline> _lines = [];
  List<Marker> _markers = [];
  LatLng _center = const LatLng(39.9042, 116.4074);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final hist = await _repo.history(days: _days);
      final mems = await _repo.memoriesWithLocation();
      final geos = await _repo.geofences();

      // 按用户分组绘制轨迹（最多两条折线：你=蓝、Ta=粉）
      final byUser = <String, List<LatLng>>{};
      LatLng? last;
      for (final h in hist) {
        final uid = h['user_id'] as String;
        final p = LatLng(
          (h['lat'] as num).toDouble(),
          (h['lng'] as num).toDouble(),
        );
        byUser.putIfAbsent(uid, () => []).add(p);
        last = p;
      }
      final colors = [const Color(0xFF3B82F6), const Color(0xFFE96A8B)];
      int i = 0;
      final lines = byUser.entries
          .map((e) => Polyline(
                points: e.value,
                color: colors[i++ % colors.length],
                strokeWidth: 4,
              ))
          .toList();

      final markers = <Marker>[];
      for (final g in geos) {
        markers.add(Marker(
          point: LatLng(
            (g['latitude'] as num).toDouble(),
            (g['longitude'] as num).toDouble(),
          ),
          width: 40,
          height: 40,
          child: const Icon(Icons.place, color: Colors.amber, size: 34),
        ));
      }
      for (final m in mems) {
        markers.add(Marker(
          point: LatLng(
            (m['lat'] as num).toDouble(),
            (m['lng'] as num).toDouble(),
          ),
          width: 36,
          height: 36,
          child: const Icon(Icons.favorite, color: Color(0xFFE96A8B), size: 30),
        ));
      }

      if (last != null) _center = last;
      setState(() {
        _lines = lines;
        _markers = markers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('爱情足迹'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _days,
            onSelected: (d) {
              _days = d;
              _load();
            },
            itemBuilder: (c) => const [
              PopupMenuItem(value: 7, child: Text('最近 7 天')),
              PopupMenuItem(value: 30, child: Text('最近 30 天')),
              PopupMenuItem(value: 90, child: Text('最近 90 天')),
              PopupMenuItem(value: 36500, child: Text('全部')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_days >= 36500 ? '全部' : '$_days 天'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('加载失败：$_error'))
              : FlutterMap(
                  options: MapOptions(center: _center, zoom: 12),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wuliao',
                    ),
                    PolylineLayer(polylines: _lines),
                    MarkerLayer(markers: _markers),
                  ],
                ),
    );
  }
}
