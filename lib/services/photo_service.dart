import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../data/database/app_database.dart';

/// Управление локальными фотографиями: съёмка, выбор из галереи,
/// сохранение в приватном каталоге приложения и удаление.
///
/// Никакие изображения никогда не покидают устройство.
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromCamera() => _pickAndStore(ImageSource.camera);

  Future<String?> pickFromGallery() => _pickAndStore(ImageSource.gallery);

  Future<List<String>> pickMultipleFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    final saved = <String>[];
    for (final file in files) {
      final path = await _storeFile(File(file.path));
      if (path != null) saved.add(path);
    }
    return saved;
  }

  Future<String?> _pickAndStore(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 2048);
    if (file == null) return null;
    return _storeFile(File(file.path));
  }

  Future<String?> _storeFile(File source) async {
    try {
      final dir = await AppDatabase.instance.photosDirectory();
      final ext = p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
      final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
      final destPath = p.join(dir.path, fileName);
      await source.copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Игнорируем — фото могло быть уже удалено.
    }
  }

  Future<void> deletePhotos(List<String> paths) async {
    for (final path in paths) {
      await deletePhoto(path);
    }
  }
}
