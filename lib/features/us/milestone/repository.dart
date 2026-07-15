import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

/// 纪念日 + 在一起天数仓储。
/// 数据库 schema: milestones(id, couple_id, title, milestone_date, icon, color, ...)
class MilestoneRepository {
  Future<String?> _coupleId() => currentCoupleId();

  Future<List<Map<String, dynamic>>> list() async {
    final cid = await _coupleId();
    if (cid == null) return [];
    final rows = await supabase
        .from('milestones')
        .select()
        .eq('couple_id', cid)
        .order('milestone_date');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> add({
    required String title,
    required DateTime date,
    String? emoji,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final cid = await _coupleId();
    // 数据库列名: milestone_date (不是 m_date), icon (不是 emoji)
    await supabase.from('milestones').insert({
      'couple_id': cid,
      'title': title,
      'milestone_date': date.toIso8601String().substring(0, 10),
      'icon': emoji ?? '💖',
      'color': '#FF6B6B',
      'repeats_yearly': false,
    });
  }

  Future<void> remove(String id) async {
    await supabase.from('milestones').delete().eq('id', id);
  }

  /// 获取在一起的天数（使用 couples 表的 paired_at 或 anniversary）
  Future<DateTime?> togetherSince() async {
    final cid = await _coupleId();
    if (cid == null) return null;
    final r = await supabase
        .from('couples')
        .select('anniversary, paired_at')
        .eq('id', cid)
        .maybeSingle();
    // 优先用 anniversary（纪念日/在一起日期），其次用 paired_at
    final v = r?['anniversary'] as String? ?? r?['paired_at'] as String?;
    return v == null ? null : DateTime.parse(v);
  }

  Future<void> setTogetherSince(DateTime d) async {
    final cid = await _coupleId();
    if (cid == null) return;
    // 更新 anniversary 字段
    await supabase
        .from('couples')
        .update({'anniversary': d.toIso8601String().substring(0, 10)})
        .eq('id', cid);
  }
}
