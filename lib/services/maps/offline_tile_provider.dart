import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Тайл-провайдер с локальным кэшем на диске.
///
/// Архитектура офлайн-карты: каждый загруженный тайл сохраняется в
/// каталоге приложения `tile_cache/{z}/{x}/{y}.png`. Если тайл уже был
/// закэширован (например, пользователь заранее скачал область карты),
/// он читается с диска без обращения к сети — карта работает полностью
/// офлайн для ранее посещённых/загруженных областей.
class OfflineFirstTileProvider extends TileProvider {
  OfflineFirstTileProvider({required this.cacheDirPath, super.headers});

  final String cacheDirPath;

  String cachePathFor(int z, int x, int y) => p.join(cacheDirPath, '$z', '$x', '$y.png');

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    final cachePath = cachePathFor(coordinates.z, coordinates.x, coordinates.y);
    return _CachedTileImageProvider(url: url, cacheFilePath: cachePath, headers: headers);
  }
}

class _CachedTileImageProvider extends ImageProvider<_CachedTileImageProvider> {
  const _CachedTileImageProvider({
    required this.url,
    required this.cacheFilePath,
    required this.headers,
  });

  final String url;
  final String cacheFilePath;
  final Map<String, String> headers;

  @override
  Future<_CachedTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_CachedTileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(_CachedTileImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1,
      debugLabel: url,
      informationCollector: () => [DiagnosticsProperty('URL', url)],
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    try {
      final file = File(cacheFilePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
        }
      }
      final response = await http.get(Uri.parse(url), headers: headers).timeout(
            const Duration(seconds: 12),
          );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        unawaited(_saveToCache(response.bodyBytes));
        return decode(await ui.ImmutableBuffer.fromUint8List(response.bodyBytes));
      }
      throw Exception('Не удалось загрузить тайл: ${response.statusCode}');
    } catch (_) {
      return decode(await ui.ImmutableBuffer.fromUint8List(TileProvider.transparentImage));
    }
  }

  Future<void> _saveToCache(Uint8List bytes) async {
    try {
      final file = File(cacheFilePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      // Кэш не критичен для работы — молча игнорируем ошибку записи.
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImageProvider && other.cacheFilePath == cacheFilePath;

  @override
  int get hashCode => cacheFilePath.hashCode;
}
