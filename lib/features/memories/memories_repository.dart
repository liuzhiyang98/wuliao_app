import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/local_db.dart';
import '../../core/supabase.dart';
import '../../models/memory.dart';

/// 共同回忆仓储。
/// 数据库 schema: memories(id, couple_id, created_by, title, description, image_urls[],
///   memory_date, latitude, longitude, location_name, created_at)
class MemoriesRepository {
  /// 读取两人共享的回忆
  Future<List<Memory>> list() async {
    final cid = await _coupleId();
    if (cid == null) return [];
    try {
      final rows = await supabase
          .from('memories')
          .select()
          .eq('couple_id', cid)
          .order('created_at', ascending: false);
      for (final r in rows) {
        await LocalDb.cacheMemory(r);
      }
      // 将数据库字段映射到 Memory 模型
      return rows.map((r) => _mapRowToMemory(r)).toList();
    } catch (_) {
      final cached = await LocalDb.cachedMemories();
      return cached.map((m) => Memory.fromJson(m)).toList();
    }
  }

  /// 新增一条回忆
  Future<void> add(Memory m) async {
    final cid = await _coupleId();
    if (cid == null) return;
    
    // 映射 Memory 字段到数据库列名
    final row = <String, dynamic>{
      'couple_id': cid,
      'created_by': supabase.auth.currentUser!.id,
      'title': m.content.length > 50 ? m.content.substring(0, 50) : m.content,
      'description': m.content,
      'memory_date': DateTime.now().toIso8601String().substring(0, 10),
      'type': m.type,
    };
    
    await supabase.from('memories').insert(row);
    await LocalDb.cacheMemory(row);
  }

  /// 选一张照片：上传到 Supabase Storage
  Future<void> addPhoto(String localPath) async {
    final cid = await _coupleId();
    if (cid == null) return;
    final file = File(localPath);
    final path = '$cid/${const Uuid().v4()}.jpg';
    await supabase.storage.from('memories').upload(path, file);
    final url = supabase.storage.from('memories').getPublicUrl(path);
    // 存储为图片URL（数据库用 image_urls[] 数组）
    await add(Memory(
      uuid: const Uuid().v4(),
      type: 'photo',
      content: url,
      createdAt: DateTime.now(),
    ));
  }

  String newUuid() => const Uuid().v4();

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

  /// 将数据库行映射到 Memory 对象
  Memory _mapRowToMemory(Map<String, dynamic> row) {
    return Memory(
      uuid: row['id'] ?? newUuid(),
      type: row['image_urls'] != null && (row['image_urls'] as List).isNotEmpty ? 'photo' : 'text',
      content: row['title'] ?? row['description'] ?? '',
      createdAt: row['created_at'] != null 
        ? DateTime.parse(row['created_at']) 
        : DateTime.now(),
    );
  }
}
