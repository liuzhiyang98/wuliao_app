import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

/// 共同歌单 + 一起看片仓储。
/// 数据库 schema:
///   songlist: (id, added_by, title, artist, platform, url, note, added_at)
///   watchlist: (id, added_by, title, type, platform, poster_url, current_episode,
///              total_episodes, status, note, added_at)
/// 注意：这两个表没有 couple_id 字段，只有 added_by
class MediaRepository {
  Future<String?> _coupleId() => currentCoupleId();

  Future<List<Map<String, dynamic>>> songs() async {
    final cid = await _coupleId();
    if (cid == null) return [];
    // 获取情侣双方 ID
    final couple = await supabase.from('couples').select('user_a, user_b').eq('id', cid).maybeSingle();
    if (couple == null) return [];
    
    final rows = await supabase
        .from('songlist')
        .select()
        .or('added_by.eq.${couple['user_a']},added_by.eq.${couple['user_b']}')
        .order('added_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addSong(String title, String? artist) async {
    final uid = supabase.auth.currentUser!.id;
    // songlist 没有 couple_id
    await supabase.from('songlist').insert({
      'added_by': uid,
      'title': title,
      'artist': artist,
    });
  }

  Future<void> removeSong(String id) async =>
      supabase.from('songlist').delete().eq('id', id);

  Future<List<Map<String, dynamic>>> watch() async {
    final cid = await _coupleId();
    if (cid == null) return [];
    final couple = await supabase.from('couples').select('user_a, user_b').eq('id', cid).maybeSingle();
    if (couple == null) return [];

    final rows = await supabase
        .from('watchlist')
        .select()
        .or('added_by.eq.${couple['user_a']},added_by.eq.${couple['user_b']}')
        .order('added_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addWatch(String title, String? note) async {
    final uid = supabase.auth.currentUser!.id;
    // watchlist 字段: type(default tvshow), status(default watching), watched 用 current_episode/total_episodes 判断
    await supabase.from('watchlist').insert({
      'added_by': uid,
      'title': title,
      'note': note,
      'type': 'movie',
      'status': 'plan_to_watch',
    });
  }

  Future<void> toggleWatched(String id, bool v) async =>
      supabase.from('watchlist').update({
        'current_episode': v ? 9999 : 0,
        'status': v ? 'completed' : 'watching',
      }).eq('id', id);

  Future<void> removeWatch(String id) async =>
      supabase.from('watchlist').delete().eq('id', id);
}
