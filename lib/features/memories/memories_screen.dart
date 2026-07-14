import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/memory.dart';
import 'add_memory_sheet.dart';
import 'memories_repository.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _repo = MemoriesRepository();
  List<Memory> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.list();
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我们的回忆')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('还没有回忆，点右下角记录第一刻吧 💕'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final m = _items[i];
                    return ListTile(
                      leading: Icon(
                        m.type == 'photo' ? Icons.photo : Icons.favorite,
                        color: const Color(0xFFE96A8B),
                      ),
                      title: Text(
                        m.content ?? (m.type == 'photo' ? '一张照片' : '瞬间'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd HH:mm')
                            .format(m.createdAt.toLocal()),
                        style:
                            const TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddMemorySheet(repo: _repo),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
