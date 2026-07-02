import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/fishing_spot.dart';
import '../../data/repositories/spot_repository.dart';
import '../../providers/app_data_bus.dart';
import '../../services/location_service.dart';
import '../../services/maps/offline_tile_provider.dart';
import '../../services/maps/tile_cache_service.dart';
import '../spots/spot_form_screen.dart';

/// Экран «Карта»: собственные метки, GPS-позиция, измерение расстояний
/// и загрузка тайлов для офлайн-использования.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum _MapTool { none, measure }

class _MapScreenState extends State<MapScreen> {
  final _spotRepo = SpotRepository();
  final _location = LocationService();
  final _tileCache = TileCacheService();
  final MapController _mapController = MapController();

  List<FishingSpot> _spots = [];
  LatLng? _myPosition;
  bool _loading = true;
  bool _showFavoritesOnly = false;
  _MapTool _tool = _MapTool.none;
  final List<LatLng> _measurePoints = [];
  String? _tileCacheDir;
  bool _downloading = false;
  double _downloadProgress = 0;

  static const LatLng _defaultCenter = LatLng(55.751244, 37.618423); // Москва

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _tileCacheDir = await _tileCache.cacheDirPath();
    await _loadSpots();
    final pos = await _location.getCurrentPosition();
    if (mounted) setState(() => _myPosition = pos);
  }

  Future<void> _loadSpots() async {
    setState(() => _loading = true);
    final spots = await _spotRepo.getAll(onlyFavorites: _showFavoritesOnly);
    if (mounted) setState(() { _spots = spots; _loading = false; });
  }

  Color _colorFromHex(String? hex) {
    if (hex == null) return AppColors.blue;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.blue;
    }
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    if (_tool == _MapTool.measure) {
      setState(() => _measurePoints.add(point));
      return;
    }
    _showAddSpotSheet(point);
  }

  Future<void> _showAddSpotSheet(LatLng point) async {
    final created = await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SpotFormScreen(initialLat: point.latitude, initialLng: point.longitude),
    ));
    if (created != null) {
      context.read<AppDataBus>().notifyChanged();
      _loadSpots();
    }
  }

  double get _measureDistanceKm => _location.totalDistanceKm(_measurePoints);

  Future<void> _downloadVisibleRegion() async {
    final bounds = _mapController.camera.visibleBounds;
    final estimate = await _tileCache.estimateTileCount(bounds: bounds, minZoom: 12, maxZoom: 16);
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Скачать область карты?'),
        content: Text('Будет загружено примерно $estimate тайлов для использования без интернета в этой области (масштаб 12–16).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Скачать')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _downloading = true; _downloadProgress = 0; });
    await _tileCache.downloadRegion(
      bounds: bounds,
      minZoom: 12,
      maxZoom: 16,
      onProgress: (p) {
        if (mounted) setState(() => _downloadProgress = p.ratio);
      },
    );
    if (mounted) {
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Область карты сохранена для офлайн-использования')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _myPosition ?? (_spots.isNotEmpty ? LatLng(_spots.first.latitude, _spots.first.longitude) : _defaultCenter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта'),
        actions: [
          IconButton(
            tooltip: 'Только избранные',
            icon: Icon(_showFavoritesOnly ? Icons.star_rounded : Icons.star_outline_rounded),
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
              _loadSpots();
            },
          ),
          IconButton(
            tooltip: 'Скачать карту офлайн',
            icon: const Icon(Icons.download_for_offline_rounded),
            onPressed: _downloading ? null : _downloadVisibleRegion,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_tileCacheDir != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: TileCacheService.tileUrlTemplate,
                  userAgentPackageName: 'com.fishlog.russia.fishlog_russia',
                  tileProvider: OfflineFirstTileProvider(cacheDirPath: _tileCacheDir!),
                ),
                if (_measurePoints.length > 1)
                  PolylineLayer(polylines: [
                    Polyline(points: _measurePoints, color: AppColors.blue, strokeWidth: 4),
                  ]),
                MarkerLayer(markers: [
                  if (_myPosition != null)
                    Marker(
                      point: _myPosition!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ..._spots.map((spot) => Marker(
                        point: LatLng(spot.latitude, spot.longitude),
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () => _showSpotSheet(spot),
                          child: Icon(
                            spot.markerType == 'danger' ? Icons.warning_rounded : Icons.location_on_rounded,
                            color: _colorFromHex(spot.color),
                            size: 38,
                          ),
                        ),
                      )),
                  ..._measurePoints.map((p) => Marker(
                        point: p,
                        width: 14,
                        height: 14,
                        child: Container(decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                      )),
                ]),
              ],
            ),
          if (_loading) const Positioned(top: 12, left: 0, right: 0, child: Center(child: CircularProgressIndicator())),
          if (_downloading)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Загрузка тайлов для офлайн-карты...'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _downloadProgress),
                    ],
                  ),
                ),
              ),
            ),
          if (_tool == _MapTool.measure)
            Positioned(
              left: 16,
              right: 16,
              top: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.straighten_rounded),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Расстояние: ${_measureDistanceKm.toStringAsFixed(2)} км · нажмите на карту, чтобы добавить точку')),
                      TextButton(
                        onPressed: () => setState(() { _tool = _MapTool.none; _measurePoints.clear(); }),
                        child: const Text('Готово'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'measure_fab',
            mini: true,
            onPressed: () => setState(() {
              _tool = _tool == _MapTool.measure ? _MapTool.none : _MapTool.measure;
              _measurePoints.clear();
            }),
            backgroundColor: _tool == _MapTool.measure ? Theme.of(context).colorScheme.secondary : null,
            child: const Icon(Icons.straighten_rounded),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'locate_fab',
            mini: true,
            onPressed: () async {
              final pos = await _location.getCurrentPosition();
              if (pos != null) {
                setState(() => _myPosition = pos);
                _mapController.move(pos, 14);
              }
            },
            child: const Icon(Icons.my_location_rounded),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add_spot_fab',
            onPressed: () => _showAddSpotSheet(_mapController.camera.center),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text('Место'),
          ),
        ],
      ),
    );
  }

  void _showSpotSheet(FishingSpot spot) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(spot.markerType == 'danger' ? Icons.warning_rounded : Icons.place_rounded, color: _colorFromHex(spot.color)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(spot.name, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                  if (spot.isFavorite) const Icon(Icons.star_rounded, color: Colors.amber),
                ],
              ),
              if (spot.notes != null && spot.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(spot.notes!),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SpotFormScreen(existing: spot)));
                        _loadSpots();
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Изменить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
