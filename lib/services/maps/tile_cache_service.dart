import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../data/database/app_database.dart';

class TileDownloadProgress {
  final int done;
  final int total;

  const TileDownloadProgress(this.done, this.total);

  double get ratio => total == 0 ? 0 : done / total;
}

/// Сервис кэширования тайлов карты для офлайн-использования.
///
/// Пользователь может заранее «скачать» видимую область карты — тайлы
/// сохраняются в локальном хранилище приложения и в дальнейшем читаются
/// без обращения к интернету через [OfflineFirstTileProvider].
class TileCacheService {
  static const String tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  Future<String> cacheDirPath() async {
    final dir = await AppDatabase.instance.tileCacheDirectory();
    return dir.path;
  }

  int _lonToTileX(double lon, int z) {
    return ((lon + 180.0) / 360.0 * (1 << z)).floor();
  }

  int _latToTileY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            (1 << z))
        .floor();
  }

  /// Считает список тайлов, покрывающих прямоугольную область [bounds]
  /// для диапазона уровней зума [minZoom]..[maxZoom].
  List<(int, int, int)> tilesForRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) {
    final tiles = <(int, int, int)>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final xMin = _lonToTileX(bounds.west, z);
      final xMax = _lonToTileX(bounds.east, z);
      final yMin = _latToTileY(bounds.north, z);
      final yMax = _latToTileY(bounds.south, z);
      for (var x = math.min(xMin, xMax); x <= math.max(xMin, xMax); x++) {
        for (var y = math.min(yMin, yMax); y <= math.max(yMin, yMax); y++) {
          tiles.add((z, x, y));
        }
      }
    }
    return tiles;
  }

  /// Скачивает все тайлы региона на диск. Вызывает [onProgress] по мере
  /// загрузки. Возвращает количество успешно сохранённых тайлов.
  Future<int> downloadRegion({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
    void Function(TileDownloadProgress progress)? onProgress,
  }) async {
    final tiles = tilesForRegion(bounds: bounds, minZoom: minZoom, maxZoom: maxZoom);
    final baseDir = await cacheDirPath();
    var done = 0;
    var saved = 0;

    for (final (z, x, y) in tiles) {
      final path = p.join(baseDir, '$z', '$x', '$y.png');
      final file = File(path);
      if (!await file.exists()) {
        final url = tileUrlTemplate
            .replaceAll('{z}', '$z')
            .replaceAll('{x}', '$x')
            .replaceAll('{y}', '$y');
        try {
          final response = await http
              .get(Uri.parse(url), headers: const {'User-Agent': 'FishLogRussia/1.0'})
              .timeout(const Duration(seconds: 12));
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await file.parent.create(recursive: true);
            await file.writeAsBytes(response.bodyBytes, flush: true);
            saved++;
          }
        } catch (_) {
          // Пропускаем тайл при ошибке сети — пользователь может повторить позже.
        }
      } else {
        saved++;
      }
      done++;
      onProgress?.call(TileDownloadProgress(done, tiles.length));
    }
    return saved;
  }

  Future<int> estimateTileCount({
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) {
    return Future.value(
      tilesForRegion(bounds: bounds, minZoom: minZoom, maxZoom: maxZoom).length,
    );
  }

  Future<void> clearCache() async {
    final dir = await AppDatabase.instance.tileCacheDirectory();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  Future<double> cacheSizeMb() async {
    final dir = await AppDatabase.instance.tileCacheDirectory();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total / (1024 * 1024);
  }
}
