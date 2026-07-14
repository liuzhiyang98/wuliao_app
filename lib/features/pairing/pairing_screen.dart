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

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      final code = const Uuid().v4().substring(0, 6).toUpperCase();
      final cid = await supabase
          .from('couples')
          .insert({'code': code, 'member_a': uid})
          .select('id')
          .single();
      await supabase
          .from('profiles')
          .update({'couple_id': cid['id']})
          .eq('id', uid);
      await refreshBgCredentials();
      setState(() => _myCode = code);
    } catch (e) {
      _err(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    setState(() => _loading = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      final res = await supabase
          .from('couples')
          .update({'member_b': uid})
          .eq('code', _code.text.trim().toUpperCase())
          .select('id')
          .single();
      await supabase
          .from('profiles')
          .update({'couple_id': res['id']})
          .eq('id', uid);
      await refreshBgCredentials();
      if (mounted) context.go('/');
    } catch (e) {
      _err(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _err(dynamic e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('出错了：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('绑定彼此')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('一人创建，一人加入，用同一个 6 位码把彼此绑在一起 💞'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _create,
              child: const Text('创建情侣空间'),
            ),
            if (_myCode != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText('你的绑定码：$_myCode',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            const Divider(height: 40),
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: '输入对方的绑定码',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loading ? null : _join,
              child: const Text('加入'),
            ),
          ],
        ),
      ),
    );
  }
}
