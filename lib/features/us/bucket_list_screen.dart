import 'package:flutter/material.dart';
import 'couple_meta_repository.dart';
import 'us_data.dart';

class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
  final _repo = CoupleMetaRepository();
  final Set<int> _done = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await _repo.doneBucket();
    if (mounted) {
      setState(() {
        _done.addAll(d);
        _loading = false;
      });
    }
  }

  Future<void> _toggle(int i, bool v) async {
    setState(() {
      if (v) {
        _done.add(i);
      } else {
        _done.remove(i);
      }
    });
    await _repo.toggle(i, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('100 件小事')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                LinearProgressIndicator(
                  value: _done.length / hundredThings.length,
                  color: const Color(0xFFE96A8B),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '已完成 ${_done.length} / ${hundredThings.length} 💕',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE96A8B),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: hundredThings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final done = _done.contains(i);
                      return CheckboxListTile(
                        value: done,
                        onChanged: (v) => _toggle(i, v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          hundredThings[i],
                          style: TextStyle(
                            decoration: done ? TextDecoration.lineThrough : null,
                            color: done ? Colors.black38 : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
