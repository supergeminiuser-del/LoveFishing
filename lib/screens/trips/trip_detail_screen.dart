import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../data/models/fishing_trip.dart';
import '../../data/repositories/catch_repository.dart';
import '../../data/repositories/fish_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../providers/app_data_bus.dart';
import '../catches/catch_detail_screen.dart';
import 'trip_form_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final FishingTrip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _catchRepo = CatchRepository();
  final _tripRepo = TripRepository();
  final _fishRepo = FishRepository();
  late FishingTrip _trip;
  List<dynamic> _catches = [];
  Map<String, String> _fishNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final catches = await _catchRepo.getForTrip(_trip.id);
    final fishIds = catches.map((c) => c.fishId).whereType<String>().toSet().toList();
    final fishList = await _fishRepo.getByIds(fishIds);
    if (mounted) {
      setState(() {
        _catches = catches;
        _fishNames = {for (final f in fishList) f.id: f.name};
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить рыбалку?'),
        content: const Text('Уловы, привязанные к этой рыбалке, сохранятся, но потеряют связь с ней.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      await _tripRepo.delete(_trip.id);
      if (mounted) {
        context.read<AppDataBus>().notifyChanged();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.title ?? 'Рыбалка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final updated = await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TripFormScreen(existing: _trip)));
              if (updated != null) setState(() => _trip = updated as FishingTrip);
              _load();
            },
          ),
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_trip.photoPaths.isNotEmpty) ...[
                  PhotoGalleryView(photoPaths: _trip.photoPaths),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Начало', AppFormatters.dateFull(_trip.startDate)),
                        _infoRow('Окончание', _trip.endDate != null ? AppFormatters.dateFull(_trip.endDate!) : 'Рыбалка продолжается'),
                        _infoRow('Расстояние', AppFormatters.distanceKm(_trip.distanceKm)),
                        _infoRow('Всего уловов', '${_catches.length}'),
                        if (_trip.notes != null && _trip.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_trip.notes!, style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Уловы этой рыбалки', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                if (_catches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Пока нет уловов, привязанных к этой рыбалке',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  )
                else
                  ..._catches.map((c) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(_fishNames[c.fishId] ?? 'Без вида рыбы'),
                          subtitle: Text('${AppFormatters.dateShort(c.date)} · ${AppFormatters.weight(c.weightKg)}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            await Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: c.id)));
                            _load();
                          },
                        ),
                      )),
              ],
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
