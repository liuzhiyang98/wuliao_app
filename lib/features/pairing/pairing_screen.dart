import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/supabase.dart';
import '../location/background_credentials.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _code = TextEditingController();
  String? _myCode;
  bool _loading = false;
  String? _error;

  /// 生成随机6位大写绑定码
  String _generateCode() {
    return const Uuid().v4().substring(0, 6).toUpperCase();
  }

  Future<void> _create() async {
    setState(() => _loading = true; _error = null);
    try {
      final uid = supabase.auth.currentUser!.id;
      final code = _generateCode();

      // 数据库 schema: couples(id, user_a, user_b, status, paired_at, anniversary, invite_code)
      // 创建情侣空间：user_a = 当前用户，invite_code = 绑定码，user_b 暂时为空
      // 注意：user_b 有 NOT NULL 约束，需要先插入一个占位值或修改约束
      final cid = await supabase
          .from('couples')
          .insert({
            'user_a': uid,
            'user_b': uid, // 占位：自己先填入，对方加入后更新
            'status': 'active',
            'invite_code': code,
          })
          .select('id')
          .single();

      await refreshBgCredentials();
      setState(() => _myCode = code);
    } catch (e) {
      String errMsg = e.toString();
      // 友好化错误信息
      if (errMsg.contains('null value in column') || errMsg.contains('NOT NULL')) {
        errMsg = '数据库约束冲突，请联系开发者调整表结构';
      } else if (errMsg.contains('unique') || errMsg.contains('duplicate')) {
        errMsg = '绑定码已存在，请重试';
      } else if (errMsg.contains('foreign key') || errMsg.contains('references')) {
        errMsg = '用户资料不完整，请重新登录';
      }
      setState(() => _error = errMsg.replaceAll('Exception: ', '').replaceAll('PostgrestError: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    setState(() => _loading = true; _error = null);
    try {
      final uid = supabase.auth.currentUser!.id;
      final inputCode = _code.text.trim().toUpperCase();
      if (inputCode.length != 6) {
        throw Exception('请输入6位绑定码');
      }

      // 通过 invite_code 查找情侣空间
      final existing = await supabase
          .from('couples')
          .select('id, user_a')
          .eq('invite_code', inputCode)
          .maybeSingle();

      if (existing == null) {
        throw Exception('绑定码无效或已过期');
      }

      if (existing['user_a'] == uid) {
        throw Exception('不能加入自己创建的空间');
      }

      // 更新 user_b 为当前用户
      await supabase
          .from('couples')
          .update({'user_b': uid})
          .eq('id', existing['id']);

      await refreshBgCredentials();
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', '').replaceAll('PostgrestError: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearError() => setState(() => _error = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('绑定彼此')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo 区域
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFCEAF0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('💕', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '一人创建，一人加入\n用同一个 6 位码把彼此绑在一起',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),

            // 创建按钮区域
            FilledButton(
              onPressed: _loading || _myCode != null ? null : _create,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(_loading
                  ? '创建中...'
                  : (_myCode != null ? '已创建 ✅' : '🎀 创建我们的情侣空间')),
            ),

            // 显示绑定码
            if (_myCode != null) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB6C1), width: 2),
                ),
                child: Column(
                  children: [
                    const Text('你的专属绑定码', style: TextStyle(
                      fontSize: 14, color: Colors.black54,
                    )),
                    const SizedBox(height: 12),
                    SelectableText(
                      _myCode!,
                      style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold,
                        letterSpacing: 8, color: Color(0xFFE96A8B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '↑ 把这个码发给 Ta\n让Ta在下方输入即可完成配对',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // 复制到剪贴板（Web环境可能不支持）
                        try {} catch (_) {}
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('绑定码已复制！快发给 Ta 吧 💌')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('复制绑定码'),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 48),

            // 加入区域
            Text('收到对方的码？在这里输入 👇',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),

            TextField(
              controller: _code,
              onChanged: (_) => _clearError(),
              decoration: InputDecoration(
                labelText: '输入 6 位绑定码',
                hintText: '例如: A1B2C3',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                suffixIcon: _code.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _code.clear(); _clearError(); })
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 4),
            ),

            const SizedBox(height: 16),

            FilledButton.tonal(
              onPressed: _loading ? null : _join,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(_loading ? '加入中...' : '💝 加入情侣空间'),
            ),

            // 错误提示
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            Text(
              '💡 提示：绑定码一次性使用\n双方各用邮箱登录后即可完成配对',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
