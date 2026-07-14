import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: 在 https://supabase.com 新建一个免费项目，
// 打开 Project Settings -> API，把下面两个值填进来。
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

Future<void> initSupabase() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}

SupabaseClient get supabase => Supabase.instance.client;

/// 当前用户所在的情侣空间 id（隐私校验依赖它）。
Future<String?> currentCoupleId() async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return null;
  try {
    final r = await supabase
        .from('profiles')
        .select('couple_id')
        .eq('id', uid)
        .single();
    return r['couple_id'] as String?;
  } catch (_) {
    return null;
  }
}
