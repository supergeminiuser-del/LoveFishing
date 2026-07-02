import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/theme_provider.dart';
import '../../services/backup_service.dart';
import '../../services/settings_service.dart';
import '../../services/maps/tile_cache_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/database/app_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupService = BackupService();
  final _settingsService = SettingsService();
  final _tileCache = TileCacheService();
  bool _busy = false;
  double _tileCacheMb = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final mb = await _tileCache.cacheSizeMb();
    if (mounted) setState(() => _tileCacheMb = mb);
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    final result = await _backupService.exportBackup();
    await _settingsService.setLastBackupAt(DateTime.now());
    setState(() => _busy = false);
    if (!mounted) return;
    if (result.success && result.filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Резервная копия создана')));
      await Share.shareXFiles([XFile(result.filePath!)], text: 'Резервная копия FishLog Russia');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: ${result.error}')));
    }
  }

  Future<void> _importBackup() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
    if (picked == null || picked.files.single.path == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Восстановить из копии?'),
        content: const Text('Текущие данные будут заменены содержимым резервной копии. Это действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Восстановить')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    final result = await _backupService.importBackup(picked.files.single.path!);
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.success ? 'Данные восстановлены. Перезапустите приложение.' : 'Ошибка: ${result.error}')),
    );
  }

  Future<void> _clearTileCache() async {
    await _tileCache.clearCache();
    await _loadCacheSize();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Кэш карты очищен')));
  }

  Future<void> _resetAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить все данные?'),
        content: const Text('Все рыбы, уловы, приманки, снаряжение, места и рыбалки будут безвозвратно удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить всё')),
        ],
      ),
    );
    if (confirm == true) {
      await AppDatabase.instance.resetDatabase();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Все данные удалены')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Оформление'),
          Card(
            child: Column(
              children: [
                RadioListTile<AppThemeMode>(
                  title: const Text('Тёмная тема'),
                  value: AppThemeMode.dark,
                  groupValue: themeProvider.mode,
                  onChanged: (v) => themeProvider.setMode(v!),
                ),
                RadioListTile<AppThemeMode>(
                  title: const Text('Светлая тема'),
                  value: AppThemeMode.light,
                  groupValue: themeProvider.mode,
                  onChanged: (v) => themeProvider.setMode(v!),
                ),
                RadioListTile<AppThemeMode>(
                  title: const Text('Как в системе'),
                  value: AppThemeMode.system,
                  groupValue: themeProvider.mode,
                  onChanged: (v) => themeProvider.setMode(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Резервное копирование'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded),
                  title: const Text('Экспортировать данные'),
                  subtitle: const Text('Создать архив базы данных и фото'),
                  onTap: _busy ? null : _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('Импортировать данные'),
                  subtitle: const Text('Восстановить из ранее сохранённого архива'),
                  onTap: _busy ? null : _importBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Офлайн-карта'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.map_rounded),
              title: const Text('Очистить кэш карты'),
              subtitle: Text('Занято: ${_tileCacheMb.toStringAsFixed(1)} МБ'),
              onTap: _clearTileCache,
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Данные'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: const Text('Удалить все данные', style: TextStyle(color: Colors.red)),
              onTap: _resetAllData,
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('О приложении'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FishLog Russia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Версия 1.0.0'),
                  SizedBox(height: 6),
                  Text('Полностью офлайн-приложение. Все данные хранятся только на вашем устройстве. '
                      'Нет аккаунтов, синхронизации, рекламы и аналитики.'),
                ],
              ),
            ),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
    );
  }
}
