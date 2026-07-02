import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../data/models/fishing_spot.dart';
import '../../data/repositories/spot_repository.dart';
import '../../providers/app_data_bus.dart';
import '../../services/location_service.dart';

class SpotFormScreen extends StatefulWidget {
  final FishingSpot? existing;
  final double? initialLat;
  final double? initialLng;

  const SpotFormScreen({super.key, this.existing, this.initialLat, this.initialLng});

  @override
  State<SpotFormScreen> createState() => _SpotFormScreenState();
}

class _SpotFormScreenState extends State<SpotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = SpotRepository();
  final _location = LocationService();

  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  String _markerType = MarkerTypeOptions.spot;
  String _color = '#2E7DF7';
  bool _favorite = false;
  List<String> _photos = [];
  bool _saving = false;
  bool _locating = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
    _lat = TextEditingController(text: (s?.latitude ?? widget.initialLat)?.toString() ?? '');
    _lng = TextEditingController(text: (s?.longitude ?? widget.initialLng)?.toString() ?? '');
    _markerType = s?.markerType ?? MarkerTypeOptions.spot;
    _color = s?.color ?? '#2E7DF7';
    _favorite = s?.isFavorite ?? false;
    _photos = List.of(s?.photoPaths ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final pos = await _location.getCurrentPosition();
    if (mounted) {
      setState(() {
        _locating = false;
        if (pos != null) {
          _lat.text = pos.latitude.toStringAsFixed(6);
          _lng.text = pos.longitude.toStringAsFixed(6);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось определить местоположение')),
          );
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_lat.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.replaceAll(',', '.'));
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Укажите корректные координаты')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final spot = FishingSpot(
      id: widget.existing?.id ?? IdGenerator.next(),
      name: _name.text.trim(),
      latitude: lat,
      longitude: lng,
      markerType: _markerType,
      color: _color,
      isFavorite: _favorite,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      photoPaths: _photos,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (_isEditing) {
      await _repo.update(spot);
    } else {
      await _repo.insert(spot);
    }
    if (mounted) {
      context.read<AppDataBus>().notifyChanged();
      Navigator.of(context).pop(spot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать место' : 'Новое место')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PhotoPickerField(photoPaths: _photos, onChanged: (v) => setState(() => _photos = v)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название места *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  decoration: const InputDecoration(labelText: 'Широта *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите широту' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  decoration: const InputDecoration(labelText: 'Долгота *'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите долготу' : null,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
              label: const Text('Использовать текущее местоположение'),
            ),
            const SizedBox(height: 18),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: MarkerTypeOptions.spot, label: Text('Место ловли'), icon: Icon(Icons.place_rounded)),
                ButtonSegment(value: MarkerTypeOptions.danger, label: Text('Опасная зона'), icon: Icon(Icons.warning_amber_rounded)),
              ],
              selected: {_markerType},
              onSelectionChanged: (v) => setState(() => _markerType = v.first),
            ),
            const SizedBox(height: 18),
            const Text('Цвет маркера', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: AppColors.markerColors.map((c) {
                final hex = '#${c.toARGB32().toRadixString(16).substring(2)}';
                final selected = hex.toUpperCase() == _color.toUpperCase();
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: selected ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8)] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Заметки'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Избранное место'),
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Сохранить изменения' : 'Добавить место'),
            ),
          ],
        ),
      ),
    );
  }
}
