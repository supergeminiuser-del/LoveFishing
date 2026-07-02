import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../core/constants/app_constants.dart';
import '../core/utils/formatters.dart';
import '../data/database/app_database.dart';

class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;

  const BackupResult({required this.success, this.filePath, this.error});
}

/// Резервное копирование и восстановление локальной базы данных и фото.
///
/// Архив создаётся и хранится только на устройстве. Экспорт за пределы
/// устройства выполняется исключительно вручную самим пользователем
/// (например, через системный диалог «Поделиться»).
class BackupService {
  static const String dbEntryName = 'fishlog_russia.db';
  static const String photosEntryPrefix = 'photos/';

  Future<BackupResult> exportBackup({bool keepInBackupsFolder = true}) async {
    try {
      final db = AppDatabase.instance;
      final docs = await db.documentsPath;
      final dbFile = File(p.join(docs, AppConstants.dbName));
      if (!await dbFile.exists()) {
        return const BackupResult(success: false, error: 'База данных не найдена');
      }

      final archive = Archive();
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile(dbEntryName, dbBytes.length, dbBytes));

      final photosDir = await db.photosDirectory();
      if (await photosDir.exists()) {
        await for (final entity in photosDir.list()) {
          if (entity is File) {
            final bytes = await entity.readAsBytes();
            final name = '$photosEntryPrefix${p.basename(entity.path)}';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        return const BackupResult(success: false, error: 'Не удалось создать архив');
      }

      final backupsDir = await db.backupsDirectory();
      final fileName = 'fishlog_backup_${AppFormatters.fileStamp(DateTime.now())}.zip';
      final outFile = File(p.join(backupsDir.path, fileName));
      await outFile.writeAsBytes(zipData, flush: true);

      return BackupResult(success: true, filePath: outFile.path);
    } catch (e) {
      return BackupResult(success: false, error: e.toString());
    }
  }

  Future<BackupResult> importBackup(String zipFilePath) async {
    try {
      final zipFile = File(zipFilePath);
      if (!await zipFile.exists()) {
        return const BackupResult(success: false, error: 'Файл резервной копии не найден');
      }
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final db = AppDatabase.instance;
      await db.close();

      final docs = await db.documentsPath;
      final dbEntry = archive.files.firstWhere(
        (f) => f.name == dbEntryName,
        orElse: () => throw Exception('В архиве не найдена база данных'),
      );
      final dbOut = File(p.join(docs, AppConstants.dbName));
      await dbOut.writeAsBytes(dbEntry.content as List<int>, flush: true);

      final photosDir = await db.photosDirectory();
      for (final file in archive.files) {
        if (file.isFile && file.name.startsWith(photosEntryPrefix)) {
          final fileName = file.name.substring(photosEntryPrefix.length);
          if (fileName.isEmpty) continue;
          final outPath = p.join(photosDir.path, fileName);
          await File(outPath).writeAsBytes(file.content as List<int>, flush: true);
        }
      }

      // Переоткрываем базу данных с восстановленными данными.
      await db.database;

      return BackupResult(success: true, filePath: zipFilePath);
    } catch (e) {
      return BackupResult(success: false, error: e.toString());
    }
  }

  Future<List<FileSystemEntity>> listLocalBackups() async {
    final dir = await AppDatabase.instance.backupsDirectory();
    if (!await dir.exists()) return [];
    final files = await dir.list().toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Создаёт автоматическую резервную копию, если последняя копия
  /// старше [minInterval] (по умолчанию — раз в сутки), и хранит не более
  /// [maxKept] последних копий.
  Future<void> maybeCreateAutomaticBackup({
    Duration minInterval = const Duration(days: 1),
    int maxKept = 5,
  }) async {
    final backups = await listLocalBackups();
    if (backups.isNotEmpty) {
      final latest = backups.first;
      final stat = await latest.stat();
      if (DateTime.now().difference(stat.modified) < minInterval) {
        return;
      }
    }
    await exportBackup();
    final updated = await listLocalBackups();
    if (updated.length > maxKept) {
      for (final old in updated.sublist(maxKept)) {
        try {
          await old.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
