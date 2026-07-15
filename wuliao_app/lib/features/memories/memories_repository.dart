import '../../core/supabase.dart';

/// 回忆数据模型
class Memory {
  final String? content;
  final String? type;
  final String? uuid;
  final DateTime? createdAt;
  
  Memory({this.content, this.type, this.uuid, this.createdAt});
}

/// 回忆仓库（存根）
class MemoriesRepository {
  Future<List<Memory>> fetchMemories() async => [];
  
  Map<String, dynamic> toMap(Memory m) => {
    'title': (m.content?.length ?? 0) > 50 ? m.content!.substring(0, 50) : m.content ?? '',
    'description': m.content,
    'type': m.type,
  };
}
