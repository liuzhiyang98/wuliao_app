import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/memory.dart';
import 'memories_repository.dart';

class AddMemorySheet extends StatefulWidget {
  final MemoriesRepository repo;
  const AddMemorySheet({super.key, required this.repo});

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
  final _text = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _saveText() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    await widget.repo.add(Memory(
      uuid: widget.repo.newUuid(),
      type: 'text',
      content: t,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    await widget.repo.addPhoto(x.path);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('记录这一刻',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            decoration:
                const InputDecoration(labelText: '写点什么…', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(onPressed: _saveText, child: const Text('保存文字')),
              const SizedBox(width: 12),
              FilledButton.tonal(
                  onPressed: _pickPhoto, child: const Text('加照片')),
            ],
          ),
        ],
      ),
    );
  }
}
