import 'package:flutter/material.dart';
import 'media_repository.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen>
    with SingleTickerProviderStateMixin {
  final _repo = MediaRepository();
  late TabController _tab;
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _watch = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await _repo.songs();
    final w = await _repo.watch();
    if (mounted) {
      setState(() {
        _songs = s;
        _watch = w;
        _loading = false;
      });
    }
  }

  Future<void> _addSong() async {
    final t = TextEditingController();
    final a = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加歌曲'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: '歌名')),
            TextField(controller: a, decoration: const InputDecoration(labelText: '歌手（可选）')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (t.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _repo.addSong(
                  t.text.trim(), a.text.trim().isEmpty ? null : a.text.trim());
              _load();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _addWatch() async {
    final t = TextEditingController();
    final n = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('想一起看'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: '片名 / 剧名')),
            TextField(controller: n, decoration: const InputDecoration(labelText: '备注（可选）')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (t.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _repo.addWatch(
                  t.text.trim(), n.text.trim().isEmpty ? null : n.text.trim());
              _load();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我们的娱乐'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '共同歌单'),
            Tab(text: '一起看片'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                ListView.separated(
                  itemCount: _songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final s = _songs[i];
                    return Dismissible(
                      key: Key(s['id']),
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
                        await _repo.removeSong(s['id']);
                        _load();
                      },
                      child: ListTile(
                        leading: const Icon(Icons.music_note,
                            color: Color(0xFFE96A8B)),
                        title: Text(s['title']),
                        subtitle: s['artist'] == null ? null : Text(s['artist']),
                      ),
                    );
                  },
                ),
                ListView.separated(
                  itemCount: _watch.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final w = _watch[i];
                    return Dismissible(
                      key: Key(w['id']),
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
                        await _repo.removeWatch(w['id']);
                        _load();
                      },
                      child: CheckboxListTile(
                        value: w['watched'] == true,
                        onChanged: (v) async {
                          await _repo.toggleWatched(w['id'], v ?? false);
                          _load();
                        },
                        title: Text(
                          w['title'],
                          style: TextStyle(
                            decoration: w['watched'] == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: w['note'] == null ? null : Text(w['note']),
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tab.index == 0 ? _addSong() : _addWatch(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
