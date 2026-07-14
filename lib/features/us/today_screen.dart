import 'package:flutter/material.dart';
import 'mood_repository.dart';

const List<String> _moods = [
  '🥰',
  '😀',
  '😊',
  '😌',
  '🤔',
  '😴',
  '😢',
  '😡',
  '🥺',
  '😎'
];

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _repo = MoodRepository();
  Map<String, dynamic> _st = {};
  String? _mood;
  final _note = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final st = await _repo.status();
    if (mounted) {
      setState(() {
        _st = st;
        _mood = st['myMood'];
        _note.text = st['myNote'] ?? '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final morningBoth = _st['morningMe'] && _st['morningPartner'];
    final eveningBoth = _st['eveningMe'] && _st['eveningPartner'];
    return Scaffold(
      appBar: AppBar(title: const Text('今天的我们')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('早晚安', style: TextStyle(color: Colors.black54)),
          Row(
            children: [
              Expanded(
                child: _GreetCard(
                  kind: 'morning',
                  me: _st['morningMe'],
                  partner: _st['morningPartner'],
                  both: morningBoth,
                  onTap: () async {
                    await _repo.greet('morning');
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GreetCard(
                  kind: 'evening',
                  me: _st['eveningMe'],
                  partner: _st['eveningPartner'],
                  both: eveningBoth,
                  onTap: () async {
                    await _repo.greet('evening');
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('今天的心情', style: TextStyle(color: Colors.black54)),
          Wrap(
            spacing: 8,
            children: _moods
                .map(
                  (e) => ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 22)),
                    selected: _mood == e,
                    onSelected: (_) => setState(() => _mood = e),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration:
                const InputDecoration(labelText: '写一句心情（可选）', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              if (_mood == null) return;
              await _repo.saveMood(_mood!, _note.text.trim());
              _load();
            },
            child: const Text('保存心情'),
          ),
          const SizedBox(height: 16),
          if (_st['partnerMood'] != null)
            Card(
              child: ListTile(
                leading:
                    Text(_st['partnerMood'], style: const TextStyle(fontSize: 24)),
                title: const Text('Ta 今天的心情'),
              ),
            ),
        ],
      ),
    );
  }
}

class _GreetCard extends StatelessWidget {
  final String kind;
  final bool me;
  final bool partner;
  final bool both;
  final VoidCallback onTap;

  const _GreetCard({
    required this.kind,
    required this.me,
    required this.partner,
    required this.both,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = kind == 'morning' ? '早安 ☀️' : '晚安 🌙';
    final sub = both
        ? '互道${kind == 'morning' ? '早安' : '晚安'} 💞'
        : me
            ? '已发送，等 Ta…'
            : '点一下给 Ta';
    return Card(
      child: InkWell(
        onTap: me ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(sub,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
