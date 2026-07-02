import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../data/models/fishing_trip.dart';
import '../../data/repositories/trip_repository.dart';
import '../../providers/app_data_bus.dart';

class TripFormScreen extends StatefulWidget {
  final FishingTrip? existing;

  const TripFormScreen({super.key, this.existing});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TripRepository();

  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _distance;
  late DateTime _startDate;
  DateTime? _endDate;
  List<String> _photos = [];
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _distance = TextEditingController(text: t?.distanceKm?.toString() ?? '');
    _startDate = t?.startDate ?? DateTime.now();
    _endDate = t?.endDate;
    _photos = List.of(t?.photoPaths ?? []);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _distance.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final trip = FishingTrip(
      id: widget.existing?.id ?? IdGenerator.next(),
      title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      photoPaths: _photos,
      distanceKm: _distance.text.trim().isEmpty ? null : double.tryParse(_distance.text.replaceAll(',', '.')),
      favoriteCatchId: widget.existing?.favoriteCatchId,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (_isEditing) {
      await _repo.update(trip);
    } else {
      await _repo.insert(trip);
    }
    if (mounted) {
      context.read<AppDataBus>().notifyChanged();
      Navigator.of(context).pop(trip);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать рыбалку' : 'Новая рыбалка')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PhotoPickerField(photoPaths: _photos, onChanged: (v) => setState(() => _photos = v)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Название рыбалки'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: true),
                  icon: const Icon(Icons.event_rounded),
                  label: Text('Начало: ${AppFormatters.dateShort(_startDate)}'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: false),
                  icon: const Icon(Icons.event_available_rounded),
                  label: Text(_endDate == null ? 'Окончание не указано' : 'Окончание: ${AppFormatters.dateShort(_endDate!)}'),
                ),
              ),
              if (_endDate != null)
                IconButton(
                  onPressed: () => setState(() => _endDate = null),
                  icon: const Icon(Icons.close_rounded),
                ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _distance,
              decoration: const InputDecoration(labelText: 'Пройденное расстояние, км'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Заметки о рыбалке'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Сохранить изменения' : 'Создать рыбалку'),
            ),
          ],
        ),
      ),
    );
  }
}
