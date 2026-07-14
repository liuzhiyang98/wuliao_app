import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'milestone_repository.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  final _repo = MilestoneRepository();
  List<Map<String, dynamic>> _items = [];
  DateTime? _togetherSince;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.list();
    final ts = await _repo.togetherSince();
    if (mounted) {
      setState(() {
        _items = items;
        _togetherSince = ts;
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final titleCtl = TextEditingController();
    DateTime date = DateTime.now();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加纪念日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtl,
              decoration: const InputDecoration(labelText: '名称（如：恋爱纪念日）'),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (c, setSt) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日期'),
                trailing: Text(DateFormat('yyyy-MM-dd').format(date)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: c,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setSt(() => date = d);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final t = titleCtl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(ctx);
              await _repo.add(title: t, date: date);
              _load();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _setTogether() async {
    final init = _togetherSince ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      await _repo.setTogetherSince(d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _togetherSince == null
        ? null
        : DateTime.now().difference(_togetherSince!).inDays;
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    Map<String, dynamic>? next;
    for (final m in _items) {
      final md = DateTime.parse(m['m_date']);
      if (!md.isBefore(today)) {
        next = m;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('纪念日')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFFFCEAF0),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          days == null ? '—' : '$days',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE96A8B),
                          ),
                        ),
                        const Text('天 · 我们已经在一起',
                            style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: _setTogether,
                          child: Text(_togetherSince == null
                              ? '设置在一起的日子 💞'
                              : '起点：${DateFormat('yyyy-MM-dd').format(_togetherSince!)}（点击修改）'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Text(next!['emoji'] ?? '💖',
                          style: const TextStyle(fontSize: 28)),
                      title: Text('${next!['title']} · 还有'),
                      subtitle: Text(
                          '${DateTime.parse(next!['m_date']).difference(today).inDays} 天'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('所有纪念日',
                    style: TextStyle(color: Colors.black54)),
                ..._items.map(
                  (m) => Dismissible(
                    key: Key(m['id']),
                    direction: DismissDirection.endToStart,
                    background: const ColoredBox(
                      color: Colors.red,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                    ),
                    onDismissed: (_) async {
                      await _repo.remove(m['id']);
                      _load();
                    },
                    child: ListTile(
                      leading: Text(m['emoji'] ?? '💖',
                          style: const TextStyle(fontSize: 22)),
                      title: Text(m['title']),
                      subtitle: Text(DateFormat('yyyy-MM-dd')
                          .format(DateTime.parse(m['m_date']))),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton:
          FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}
