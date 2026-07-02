import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/entity_picker_sheet.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../core/widgets/rating_stars.dart';
import '../../data/models/bait.dart';
import '../../data/models/catch_record.dart';
import '../../data/models/equipment_item.dart';
import '../../data/models/fish.dart';
import '../../data/models/fishing_spot.dart';
import '../../data/models/fishing_trip.dart';
import '../../data/repositories/bait_repository.dart';
import '../../data/repositories/catch_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/fish_repository.dart';
import '../../data/repositories/spot_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../providers/app_data_bus.dart';
import '../../services/location_service.dart';
import '../baits/bait_form_screen.dart';
import '../fish/fish_form_screen.dart';
import '../spots/spot_form_screen.dart';

/// Форма добавления/редактирования улова. Обязательные поля сведены к
/// минимуму (рыба, дата, вес) — остальное можно раскрыть по желанию,
/// чтобы добавление улова занимало меньше 30 секунд.
class CatchFormScreen extends StatefulWidget {
  final CatchRecord? existing;
  final String? initialTripId;
  final String? initialSpotId;

  const CatchFormScreen({super.key, this.existing, this.initialTripId, this.initialSpotId});

  @override
  State<CatchFormScreen> createState() => _CatchFormScreenState();
}

class _CatchFormScreenState extends State<CatchFormScreen> {
  final _fishRepo = FishRepository();
  final _baitRepo = BaitRepository();
  final _spotRepo = SpotRepository();
  final _tripRepo = TripRepository();
  final _equipRepo = EquipmentRepository();
  final _catchRepo = CatchRepository();
  final _location = LocationService();

  late final TextEditingController _weight;
  late final TextEditingController _length;
  late final TextEditingController _quantity;
  late final TextEditingController _notes;
  late final TextEditingController _weatherText;
  late final TextEditingController _waterTemp;
  late final TextEditingController _airTemp;
  late final TextEditingController _wind;
  late final TextEditingController _pressure;

  Fish? _fish;
  Bait? _bait;
  FishingSpot? _spot;
  FishingTrip? _trip;
  EquipmentItem? _rod, _reel, _line, _hook, _lure;
  late DateTime _date;
  String? _method;
  String? _waterClarity;
  String? _waterLevel;
  int _rating = 0;
  double? _lat, _lng;
  List<String> _photos = [];
  bool _saving = false;
  bool _advancedOpen = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _weight = TextEditingController(text: c?.weightKg?.toString() ?? '');
    _length = TextEditingController(text: c?.lengthCm?.toString() ?? '');
    _quantity = TextEditingController(text: (c?.quantity ?? 1).toString());
    _notes = TextEditingController(text: c?.notes ?? '');
    _weatherText = TextEditingController(text: c?.weatherText ?? '');
    _waterTemp = TextEditingController(text: c?.waterTempC?.toString() ?? '');
    _airTemp = TextEditingController(text: c?.airTempC?.toString() ?? '');
    _wind = TextEditingController(text: c?.windText ?? '');
    _pressure = TextEditingController(text: c?.pressureHpa != null ? (c!.pressureHpa! * 0.750062).round().toString() : '');
    _date = c?.date ?? DateTime.now();
    _method = c?.method;
    _waterClarity = c?.waterClarity;
    _waterLevel = c?.waterLevel;
    _rating = c?.rating ?? 0;
    _lat = c?.latitude;
    _lng = c?.longitude;
    _photos = List.of(c?.photoPaths ?? []);
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    final c = widget.existing;
    final tripId = c?.tripId ?? widget.initialTripId;
    final spotId = c?.spotId ?? widget.initialSpotId;
    Fish? fish;
    Bait? bait;
    FishingSpot? spot;
    FishingTrip? trip;
    EquipmentItem? rod, reel, line, hook, lure;
    if (c?.fishId != null) fish = await _fishRepo.getById(c!.fishId!);
    if (c?.baitId != null) bait = await _baitRepo.getById(c!.baitId!);
    if (spotId != null) spot = await _spotRepo.getById(spotId);
    if (tripId != null) trip = await _tripRepo.getById(tripId);
    if (c?.rodEquipmentId != null) rod = await _equipRepo.getById(c!.rodEquipmentId!);
    if (c?.reelEquipmentId != null) reel = await _equipRepo.getById(c!.reelEquipmentId!);
    if (c?.lineEquipmentId != null) line = await _equipRepo.getById(c!.lineEquipmentId!);
    if (c?.hookEquipmentId != null) hook = await _equipRepo.getById(c!.hookEquipmentId!);
    if (c?.lureEquipmentId != null) lure = await _equipRepo.getById(c!.lureEquipmentId!);
    if (mounted) {
      setState(() {
        _fish = fish;
        _bait = bait;
        _spot = spot;
        _trip = trip;
        _rod = rod;
        _reel = reel;
        _line = line;
        _hook = hook;
        _lure = lure;
      });
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _length.dispose();
    _quantity.dispose();
    _notes.dispose();
    _weatherText.dispose();
    _waterTemp.dispose();
    _airTemp.dispose();
    _wind.dispose();
    _pressure.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ru', 'RU'),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time?.hour ?? _date.hour, time?.minute ?? _date.minute);
    });
  }

  Future<void> _pickFish() async {
    final all = await _fishRepo.getAll();
    final recent = await _fishRepo.getRecentlyUsed();
    if (!mounted) return;
    final result = await EntityPickerSheet.show<Fish>(
      context,
      title: 'Выбор рыбы',
      items: all,
      recentItems: recent,
      labelOf: (f) => f.name,
      subtitleOf: (f) => f.category,
      createLabel: 'Новая рыба',
      onCreateNew: () async {
        final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FishFormScreen()));
        if (created != null) setState(() => _fish = created as Fish);
      },
    );
    if (result != null) setState(() => _fish = result);
  }

  Future<void> _pickBait() async {
    final all = await _baitRepo.getAll();
    final recent = await _baitRepo.getRecentlyUsed();
    if (!mounted) return;
    final result = await EntityPickerSheet.show<Bait>(
      context,
      title: 'Выбор приманки',
      items: all,
      recentItems: recent,
      labelOf: (b) => b.name,
      subtitleOf: (b) => b.brand,
      createLabel: 'Новая приманка',
      onCreateNew: () async {
        final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BaitFormScreen()));
        if (created != null) setState(() => _bait = created as Bait);
      },
    );
    if (result != null) setState(() => _bait = result);
  }

  Future<void> _pickSpot() async {
    final all = await _spotRepo.getAll();
    final recent = await _spotRepo.getRecentlyUsed();
    if (!mounted) return;
    final result = await EntityPickerSheet.show<FishingSpot>(
      context,
      title: 'Выбор места',
      items: all,
      recentItems: recent,
      labelOf: (s) => s.name,
      createLabel: 'Новое место',
      onCreateNew: () async {
        final created = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpotFormScreen()));
        if (created != null) {
          setState(() {
            _spot = created as FishingSpot;
            _lat ??= _spot!.latitude;
            _lng ??= _spot!.longitude;
          });
        }
      },
    );
    if (result != null) {
      setState(() {
        _spot = result;
        _lat ??= result.latitude;
        _lng ??= result.longitude;
      });
    }
  }

  Future<void> _pickTrip() async {
    final all = await _tripRepo.getAll();
    if (!mounted) return;
    final result = await EntityPickerSheet.show<FishingTrip>(
      context,
      title: 'Привязать к рыбалке',
      items: all,
      labelOf: (t) => t.title ?? 'Рыбалка ${t.startDate.day}.${t.startDate.month}.${t.startDate.year}',
    );
    if (result != null) setState(() => _trip = result);
  }

  Future<void> _pickEquipment(String category, ValueChanged<EquipmentItem?> onSelected) async {
    final all = await _equipRepo.getAll(category: category);
    if (!mounted) return;
    final result = await EntityPickerSheet.show<EquipmentItem>(
      context,
      title: 'Выбор: ${EquipmentCategory.label(category)}',
      items: all,
      labelOf: (e) => e.name,
      subtitleOf: (e) => e.brand,
    );
    if (result != null) onSelected(result);
  }

  Future<void> _useCurrentLocation() async {
    final pos = await _location.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось определить местоположение')));
    }
  }

  Future<void> _save() async {
    if (_fish == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите рыбу')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final mmHg = _pressure.text.trim().isEmpty ? null : double.tryParse(_pressure.text.replaceAll(',', '.'));
    final pressureHpa = mmHg != null ? mmHg / 0.750062 : null;
    final record = CatchRecord(
      id: widget.existing?.id ?? IdGenerator.next(),
      fishId: _fish?.id,
      tripId: _trip?.id,
      spotId: _spot?.id,
      date: _date,
      weightKg: _weight.text.trim().isEmpty ? null : double.tryParse(_weight.text.replaceAll(',', '.')),
      lengthCm: _length.text.trim().isEmpty ? null : double.tryParse(_length.text.replaceAll(',', '.')),
      quantity: int.tryParse(_quantity.text) ?? 1,
      latitude: _lat,
      longitude: _lng,
      photoPaths: _photos,
      baitId: _bait?.id,
      lureEquipmentId: _lure?.id,
      rodEquipmentId: _rod?.id,
      reelEquipmentId: _reel?.id,
      lineEquipmentId: _line?.id,
      hookEquipmentId: _hook?.id,
      method: _method,
      weatherText: _weatherText.text.trim().isEmpty ? null : _weatherText.text.trim(),
      waterTempC: _waterTemp.text.trim().isEmpty ? null : double.tryParse(_waterTemp.text.replaceAll(',', '.')),
      airTempC: _airTemp.text.trim().isEmpty ? null : double.tryParse(_airTemp.text.replaceAll(',', '.')),
      windText: _wind.text.trim().isEmpty ? null : _wind.text.trim(),
      pressureHpa: pressureHpa != null && pressureHpa.isFinite ? pressureHpa / 1 : null,
      waterClarity: _waterClarity,
      waterLevel: _waterLevel,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      rating: _rating,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    ).copyWith(pressureHpa: pressureHpa);

    if (_isEditing) {
      await _catchRepo.update(record);
    } else {
      await _catchRepo.insert(record);
    }

    if (mounted) {
      context.read<AppDataBus>().notifyChanged();
      Navigator.of(context).pop(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать улов' : 'Новый улов')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          PhotoPickerField(photoPaths: _photos, onChanged: (v) => setState(() => _photos = v)),
          const SizedBox(height: 20),
          _pickerTile(
            icon: Icons.set_meal_rounded,
            label: 'Рыба *',
            value: _fish?.name ?? 'Выберите рыбу',
            onTap: _pickFish,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_rounded),
            label: Text('${_date.day}.${_date.month}.${_date.year}, ${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}'),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _weight,
                decoration: const InputDecoration(labelText: 'Вес, кг'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _length,
                decoration: const InputDecoration(labelText: 'Длина, см'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          TextFormField(
            controller: _quantity,
            decoration: const InputDecoration(labelText: 'Количество, шт'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _pickerTile(icon: Icons.place_rounded, label: 'Место ловли', value: _spot?.name ?? 'Не указано', onTap: _pickSpot),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _useCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
            label: Text(_lat != null ? 'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}' : 'Указать GPS-координаты'),
          ),
          const SizedBox(height: 10),
          _pickerTile(icon: Icons.directions_boat_filled_rounded, label: 'Рыбалка', value: _trip?.title ?? 'Не привязан', onTap: _pickTrip),
          const SizedBox(height: 10),
          _pickerTile(icon: Icons.bubble_chart_rounded, label: 'Приманка', value: _bait?.name ?? 'Не указана', onTap: _pickBait),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('Оценка улова:'),
              const SizedBox(width: 10),
              RatingStars(rating: _rating, onChanged: (v) => setState(() => _rating = v)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 32),
          InkWell(
            onTap: () => setState(() => _advancedOpen = !_advancedOpen),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Снаряжение, погода и подробности', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                Icon(_advancedOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              ],
            ),
          ),
          if (_advancedOpen) ...[
            const SizedBox(height: 14),
            _pickerTile(icon: Icons.sports_rounded, label: 'Удилище', value: _rod?.name ?? 'Не указано', onTap: () => _pickEquipment(EquipmentCategory.rod, (v) => setState(() => _rod = v))),
            const SizedBox(height: 10),
            _pickerTile(icon: Icons.settings_input_component_rounded, label: 'Катушка', value: _reel?.name ?? 'Не указано', onTap: () => _pickEquipment(EquipmentCategory.reel, (v) => setState(() => _reel = v))),
            const SizedBox(height: 10),
            _pickerTile(icon: Icons.linear_scale_rounded, label: 'Леска/шнур', value: _line?.name ?? 'Не указано', onTap: () => _pickEquipment(EquipmentCategory.line, (v) => setState(() => _line = v))),
            const SizedBox(height: 10),
            _pickerTile(icon: Icons.change_history_rounded, label: 'Крючок', value: _hook?.name ?? 'Не указано', onTap: () => _pickEquipment(EquipmentCategory.hook, (v) => setState(() => _hook = v))),
            const SizedBox(height: 10),
            _pickerTile(icon: Icons.bolt_rounded, label: 'Блесна/воблер', value: _lure?.name ?? 'Не указано', onTap: () => _pickEquipment(EquipmentCategory.lure, (v) => setState(() => _lure = v))),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Способ ловли'),
              items: FishingMethods.all.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _method = v),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _weatherText, decoration: const InputDecoration(labelText: 'Погода')),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _waterTemp, decoration: const InputDecoration(labelText: 'Темп. воды, °C'), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _airTemp, decoration: const InputDecoration(labelText: 'Темп. воздуха, °C'), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _wind, decoration: const InputDecoration(labelText: 'Ветер'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _pressure, decoration: const InputDecoration(labelText: 'Давление, мм рт.ст.'), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _waterClarity,
              decoration: const InputDecoration(labelText: 'Прозрачность воды'),
              items: WaterClarityOptions.all.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _waterClarity = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _waterLevel,
              decoration: const InputDecoration(labelText: 'Уровень воды'),
              items: WaterLevelOptions.all.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _waterLevel = v),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Заметки'), maxLines: 3),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'Сохранить изменения' : 'Сохранить улов'),
          ),
        ],
      ),
    );
  }

  Widget _pickerTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
