import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';
import 'us_data.dart';

/// 每日一问：按日期确定性出题，两人都答后才互相可见。
class DailyRepository {
  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String todayQuestion() {
    final epoch = DateTime(2024, 1, 1);
    final idx =
        DateTime.now().difference(epoch).inDays % dailyQuestions.length;
    return dailyQuestions[idx];
  }

  Future<String?> _coupleId() => currentCoupleId();

  /// 返回 {question, mine, partner, both}
  Future<Map<String, dynamic>> status() async {
    final cid = await _coupleId();
    if (cid == null) return {'question': todayQuestion(), 'mine': null, 'partner': null, 'both': false};
    final q = todayQuestion();
    final rows = await supabase
        .from('daily_answers')
        .select()
        .eq('couple_id', cid)
        .eq('q_date', _today());
    final me = supabase.auth.currentUser!.id;
    String? mine;
    String? partner;
    for (final r in rows) {
      if (r['user_id'] == me) {
        mine = r['answer'];
      } else {
        partner = r['answer'];
      }
    }
    return {
      'question': q,
      'mine': mine,
      'partner': partner,
      'both': mine != null && partner != null,
    };
  }

  Future<void> answer(String text) async {
    final uid = supabase.auth.currentUser!.id;
    final cid = await _coupleId();
    if (cid == null) return;
    await supabase.from('daily_answers').upsert(
      {
        'couple_id': cid,
        'q_date': _today(),
        'question': todayQuestion(),
        'user_id': uid,
        'answer': text,
      },
      onConflict: 'couple_id,q_date,user_id',
    );
  }
}
