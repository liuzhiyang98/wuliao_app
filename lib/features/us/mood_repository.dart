import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';

/// 远程早晚安 + 当天心情仓储。
class MoodRepository {
  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<String?> _coupleId() => currentCoupleId();

  Future<Map<String, dynamic>> status() async {
    final cid = await _coupleId();
    if (cid == null) return {
      'morningMe': false, 'eveningMe': false,
      'morningPartner': false, 'eveningPartner': false,
      'myMood': null, 'myNote': null, 'partnerMood': null,
    };
    final me = supabase.auth.currentUser!.id;
    final today = _today();

    final g = await supabase
        .from('greetings')
        .select()
        .eq('couple_id', cid)
        .eq('g_date', today);
    bool morningMe = false,
        eveningMe = false,
        morningP = false,
        eveningP = false;
    for (final r in g) {
      final isMe = r['user_id'] == me;
      if (r['kind'] == 'morning') {
        if (isMe) {
          morningMe = true;
        } else {
          morningP = true;
        }
      } else {
        if (isMe) {
          eveningMe = true;
        } else {
          eveningP = true;
        }
      }
    }

    final m = await supabase
        .from('moods')
        .select()
        .eq('couple_id', cid)
        .eq('m_date', today);
    String? myMood, myNote, partnerMood;
    for (final r in m) {
      if (r['user_id'] == me) {
        myMood = r['mood'];
        myNote = r['note'];
      } else {
        partnerMood = r['mood'];
      }
    }
    return {
      'morningMe': morningMe,
      'eveningMe': eveningMe,
      'morningPartner': morningP,
      'eveningPartner': eveningP,
      'myMood': myMood,
      'myNote': myNote,
      'partnerMood': partnerMood,
    };
  }

  Future<void> greet(String kind) async {
    final uid = supabase.auth.currentUser!.id;
    final cid = await _coupleId();
    if (cid == null) return;
    await supabase.from('greetings').upsert(
      {
        'couple_id': cid,
        'user_id': uid,
        'g_date': _today(),
        'kind': kind,
      },
      onConflict: 'couple_id,user_id,g_date,kind',
    );
  }

  Future<void> saveMood(String mood, String note) async {
    final uid = supabase.auth.currentUser!.id;
    final cid = await _coupleId();
    if (cid == null) return;
    await supabase.from('moods').upsert(
      {
        'couple_id': cid,
        'user_id': uid,
        'm_date': _today(),
        'mood': mood,
        'note': note,
      },
      onConflict: 'couple_id,user_id,m_date',
    );
  }
}
