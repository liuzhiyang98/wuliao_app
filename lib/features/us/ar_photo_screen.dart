import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../memories/memories_repository.dart';

/// AR 合照：打开相机拍一张两人的瞬间，自动存入「回忆」。
/// 说明：当前为「相机拍照 + 存入回忆」版本。完整的 AR 实时贴纸/虚拟同框叠加
/// 需要 arcore(Android)/ARKit(iOS) 原生能力，属进阶增强，后续可单独接入。
class ArPhotoScreen extends StatefulWidget {
  const ArPhotoScreen({super.key});

  @override
  State<ArPhotoScreen> createState() => _ArPhotoScreenState();
}

class _ArPhotoScreenState extends State<ArPhotoScreen> {
  final _picker = ImagePicker();
  final _repo = MemoriesRepository();
  bool _busy = false;

  Future<void> _capture() async {
    setState(() => _busy = true);
    try {
      final x = await _picker.pickImage(source: ImageSource.camera);
      if (x != null) {
        await _repo.addPhoto(x.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已存入你们的回忆 💕')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('拍照失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR 合照')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('打开相机，拍一张两人的瞬间，自动存进「回忆」。',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '说明：当前为「相机拍照 + 存入回忆」版本。完整的 AR 实时贴纸 / '
                  '虚拟同框叠加需要 arcore(Android) / ARKit(iOS) 原生能力，'
                  '属于进阶增强，后续可单独接入，不影响现在的使用。',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _busy
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _capture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('拍照合照'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
