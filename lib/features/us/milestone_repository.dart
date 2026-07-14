import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

/// 纪念日 + 在一起天数仓储。
class MilestoneRepository {
  Future<String?> _coupleId() => currentCoupleId();

  Future<List<Map<String, dynamic>>> list() async {
    final cid = await _coupleId();
    if (cid == null) return [];
    final rows = await supabase
        .from('milestones')
        .select()
        .eq('couple_id', cid)
        .order('m_date');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> add({
    required String title,
    required DateTime date,
    String? emoji,
  }) async {
    final uid = supabase.auth.currentUser!.id;
    final cid = await _coupleId();
    await supabase.from('milestones').insert({
      'couple_id': cid,
      'created_by': uid,
      'title': title,
      'm_date': date.toIso8601String().substring(0, 10),
      'emoji': emoji ?? '💖',
    });
  }

  Future<void> remove(String id) async {
    await supabase.from('milestones').delete().eq('id', id);
  }

  Future<DateTime?> togetherSince() async {
    final cid = await _coupleId();
    if (cid == null) return null;
    final r = await supabase
        .from('couples')
        .select('together_since')
        .eq('id', cid)
        .maybeSingle();
    final v = r?['together_since'] as String?;
    return v == null ? null : DateTime.parse(v);
  }

  Future<void> setTogetherSince(DateTime d) async {
    final cid = await _coupleId();
    if (cid == null) return;
    await supabase
        .from('couples')
        .update({'together_since': d.toIso8601String().substring(0, 10)})
        .eq('id', cid);
  }
}
