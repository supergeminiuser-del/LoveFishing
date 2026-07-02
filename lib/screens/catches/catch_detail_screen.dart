import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../core/widgets/rating_stars.dart';
import '../../data/models/bait.dart';
import '../../data/models/catch_record.dart';
import '../../data/models/equipment_item.dart';
import '../../data/models/fish.dart';
import '../../data/models/fishing_spot.dart';
import '../../data/repositories/bait_repository.dart';
import '../../data/repositories/catch_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/fish_repository.dart';
import '../../data/repositories/spot_repository.dart';
import '../../providers/app_data_bus.dart';
import 'catch_form_screen.dart';

class CatchDetailScreen extends StatefulWidget {
  final String catchId;

  const CatchDetailScreen({super.key, required this.catchId});

  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  final _catchRepo = CatchRepository();
  CatchRecord? _record;
  Fish? _fish;
  Bait? _bait;
  FishingSpot? _spot;
  EquipmentItem? _rod, _reel, _line, _hook, _lure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final record = await _catchRepo.getById(widget.catchId);
    if (record == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final fish = record.fishId != null ? await FishRepository().getById(record.fishId!) : null;
    final bait = record.baitId != null ? await BaitRepository().getById(record.baitId!) : null;
    final spot = record.spotId != null ? await SpotRepository().getById(record.spotId!) : null;
    final equipRepo = EquipmentRepository();
    final rod = record.rodEquipmentId != null ? await equipRepo.getById(record.rodEquipmentId!) : null;
    final reel = record.reelEquipmentId != null ? await equipRepo.getById(record.reelEquipmentId!) : null;
    final line = record.lineEquipmentId != null ? await equipRepo.getById(record.lineEquipmentId!) : null;
    final hook = record.hookEquipmentId != null ? await equipRepo.getById(record.hookEquipmentId!) : null;
    final lure = record.lureEquipmentId != null ? await equipRepo.getById(record.lureEquipmentId!) : null;
    if (mounted) {
      setState(() {
        _record = record;
        _fish = fish;
        _bait = bait;
        _spot = spot;
        _rod = rod;
        _reel = reel;
        _line = line;
        _hook = hook;
        _lure = lure;
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить улов?'),
        content: const Text('Запись будет удалена без возможности восстановления.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      await _catchRepo.delete(widget.catchId);
      if (mounted) {
        context.read<AppDataBus>().notifyChanged();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final record = _record;
    if (record == null) {
      return const Scaffold(body: Center(child: Text('Улов не найден')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_fish?.name ?? 'Улов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CatchFormScreen(existing: record)));
              _load();
            },
          ),
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (record.photoPaths.isNotEmpty) ...[
            PhotoGalleryView(photoPaths: record.photoPaths),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(AppFormatters.dateTime(record.date), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              RatingStars(rating: record.rating, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          _statsRow(),
          const SizedBox(height: 20),
          _sectionCard('Место и условия', [
            _row('Место ловли', _spot?.name ?? '—'),
            if (record.hasLocation) _row('Координаты', AppFormatters.coordinates(record.latitude!, record.longitude!)),
            _row('Способ ловли', record.method ?? '—'),
            _row('Погода', record.weatherText ?? '—'),
            _row('Темп. воды', AppFormatters.temperature(record.waterTempC)),
            _row('Темп. воздуха', AppFormatters.temperature(record.airTempC)),
            _row('Ветер', record.windText ?? '—'),
            _row('Давление', AppFormatters.pressure(record.pressureHpa)),
            _row('Прозрачность воды', record.waterClarity ?? '—'),
            _row('Уровень воды', record.waterLevel ?? '—'),
          ]),
          const SizedBox(height: 16),
          _sectionCard('Приманка и снаряжение', [
            _row('Приманка', _bait?.name ?? '—'),
            _row('Удилище', _rod?.name ?? '—'),
            _row('Катушка', _reel?.name ?? '—'),
            _row('Леска/шнур', _line?.name ?? '—'),
            _row('Крючок', _hook?.name ?? '—'),
            _row('Блесна/воблер', _lure?.name ?? '—'),
          ]),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionCard('Заметки', [Text(record.notes!)]),
          ],
        ],
      ),
    );
  }

  Widget _statsRow() {
    final record = _record!;
    final theme = Theme.of(context);
    Widget item(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            item('Вес', AppFormatters.weight(record.weightKg)),
            item('Длина', AppFormatters.length(record.lengthCm)),
            item('Штук', '${record.quantity}'),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
