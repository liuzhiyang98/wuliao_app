import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase.dart';
import 'us_data.dart';

/// 默契测试：两人各自悄悄选 A/B，都选完揭示是否一致。
class QuizRepository {
  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Map<String, String> todayQuestion() {
    final epoch = DateTime(2024, 1, 1);
    final idx = DateTime.now().difference(epoch).inDays % quizQuestions.length;
    return quizQuestions[idx];
  }

  Future<String?> _coupleId() => currentCoupleId();

  Future<Map<String, dynamic>> status() async {
    final cid = await _coupleId();
    if (cid == null) return {'q': todayQuestion(), 'myChoice': null, 'partnerChoice': null, 'both': false, 'match': false};
    final q = todayQuestion();
    final rows = await supabase
        .from('quiz_rounds')
        .select()
        .eq('couple_id', cid)
        .eq('q_date', _today());
    final me = supabase.auth.currentUser!.id;
    String? mine;
    String? partner;
    for (final r in rows) {
      if (r['user_id'] == me) {
        mine = r['choice'];
      } else {
        partner = r['choice'];
      }
    }
    return {
      'q': q,
      'myChoice': mine,
      'partnerChoice': partner,
      'both': mine != null && partner != null,
      'match': mine != null && partner != null && mine == partner,
    };
  }

  Future<void> choose(String choice) async {
    final uid = supabase.auth.currentUser!.id;
    final cid = await _coupleId();
    if (cid == null) return;
    final q = todayQuestion();
    await supabase.from('quiz_rounds').upsert(
      {
        'couple_id': cid,
        'q_date': _today(),
        'question': q['q'],
        'option_a': q['a'],
        'option_b': q['b'],
        'user_id': uid,
        'choice': choice,
      },
      onConflict: 'couple_id,q_date,user_id',
    );
  }
}
