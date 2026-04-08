import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndSaveImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'stock_images'));
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    final fileName = 'stock_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final savedPath = p.join(imagesDir.path, fileName);
    final savedFile = await File(picked.path).copy(savedPath);
    return savedFile.path;
  }

  Future<void> deleteImageIfExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
