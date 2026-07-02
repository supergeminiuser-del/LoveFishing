import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/photo_service.dart';
import '../constants/app_constants.dart';

/// Универсальный виджет прикрепления нескольких локальных фото к любой
/// сущности (рыба, улов, рыбалка, место, снаряжение, приманка).
class PhotoPickerField extends StatefulWidget {
  final List<String> photoPaths;
  final ValueChanged<List<String>> onChanged;

  const PhotoPickerField({super.key, required this.photoPaths, required this.onChanged});

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  final PhotoService _photoService = PhotoService();
  bool _busy = false;

  Future<void> _addPhoto() async {
    if (widget.photoPaths.length >= AppConstants.maxPhotosPerEntity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Достигнут лимит фотографий для одной записи')),
      );
      return;
    }
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.collections_rounded),
              title: const Text('Выбрать несколько фото'),
              onTap: () => Navigator.pop(ctx, 'multi'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    setState(() => _busy = true);
    try {
      if (source == 'camera') {
        final path = await _photoService.pickFromCamera();
        if (path != null) widget.onChanged([...widget.photoPaths, path]);
      } else if (source == 'gallery') {
        final path = await _photoService.pickFromGallery();
        if (path != null) widget.onChanged([...widget.photoPaths, path]);
      } else {
        final paths = await _photoService.pickMultipleFromGallery();
        if (paths.isNotEmpty) widget.onChanged([...widget.photoPaths, ...paths]);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _removeAt(int index) {
    final updated = [...widget.photoPaths]..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.photoPaths.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == widget.photoPaths.length) {
            return InkWell(
              onTap: _busy ? null : _addPhoto,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                ),
                child: _busy
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.add_a_photo_rounded, color: theme.colorScheme.primary),
              ),
            );
          }
          final path = widget.photoPaths[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(path),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 88,
                    height: 88,
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _removeAt(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Компактная сетка фотографий только для просмотра (детальные экраны).
class PhotoGalleryView extends StatelessWidget {
  final List<String> photoPaths;

  const PhotoGalleryView({super.key, required this.photoPaths});

  @override
  Widget build(BuildContext context) {
    if (photoPaths.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoPaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final path = photoPaths[index];
          return GestureDetector(
            onTap: () => _openViewer(context, photoPaths, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(path),
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openViewer(BuildContext context, List<String> paths, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoViewerScreen(paths: paths, initialIndex: initialIndex),
      fullscreenDialog: true,
    ));
  }
}

class _PhotoViewerScreen extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _PhotoViewerScreen({required this.paths, required this.initialIndex});

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} из ${widget.paths.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.file(File(widget.paths[index]), fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
