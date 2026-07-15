import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ 已配置：吾俩 App Supabase 项目
const String supabaseUrl = 'https://jvpqalqqmsueaxnvylar.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cHFhbHFtc3VlYXhudnlsYXIiLCJybxlI6ImFub24iLCJpYXQiOjE3MzE1ODk0MDQsImV4cCI6MjAyNjA4MTkwNH0.V7_kUmleHX9Hxitx8dW60CrZ_TeQ1gjIO1xJnn-Y8t4';

/// 检查 Supabase 是否已配置（占位符未替换时返回 false）
bool get isSupabaseConfigured =>
    supabaseUrl != 'YOUR_SUPABASE_URL' &&
    supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY' &&
    supabaseUrl.startsWith('http');

Future<void> initSupabase() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}

SupabaseClient get supabase => Supabase.instance.client;

/// 当前用户所在的情侣空间 id（隐私校验依赖它）。
/// 从 couples 表查询：当前用户作为 user_a 或 user_b 的活跃配对。
Future<String?> currentCoupleId() async {
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return null;
  try {
    final r = await supabase
        .from('couples')
        .select('id')
        .or('user_a.eq.$uid,user_b.eq.$uid')
        .eq('status', 'active')
        .maybeSingle();
    return r?['id'] as String?;
  } catch (_) {
    return null;
  }
}
