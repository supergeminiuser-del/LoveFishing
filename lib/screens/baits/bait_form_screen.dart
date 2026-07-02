import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../core/widgets/rating_stars.dart';
import '../../data/models/bait.dart';
import '../../data/repositories/bait_repository.dart';
import '../../providers/app_data_bus.dart';

class BaitFormScreen extends StatefulWidget {
  final Bait? existing;

  const BaitFormScreen({super.key, this.existing});

  @override
  State<BaitFormScreen> createState() => _BaitFormScreenState();
}

class _BaitFormScreenState extends State<BaitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = BaitRepository();

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _type;
  late final TextEditingController _color;
  late final TextEditingController _size;
  late final TextEditingController _weight;
  late final TextEditingController _notes;
  String? _season;
  String? _weather;
  List<String> _photos = [];
  int _rating = 0;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _name = TextEditingController(text: b?.name ?? '');
    _brand = TextEditingController(text: b?.brand ?? '');
    _type = TextEditingController(text: b?.type ?? '');
    _color = TextEditingController(text: b?.color ?? '');
    _size = TextEditingController(text: b?.size ?? '');
    _weight = TextEditingController(text: b?.weightG?.toString() ?? '');
    _notes = TextEditingController(text: b?.notes ?? '');
    _season = b?.bestSeason;
    _weather = b?.bestWeather;
    _photos = List.of(b?.photoPaths ?? []);
    _rating = b?.rating ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _type.dispose();
    _color.dispose();
    _size.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final bait = Bait(
      id: widget.existing?.id ?? IdGenerator.next(),
      name: _name.text.trim(),
      photoPaths: _photos,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      type: _type.text.trim().isEmpty ? null : _type.text.trim(),
      color: _color.text.trim().isEmpty ? null : _color.text.trim(),
      size: _size.text.trim().isEmpty ? null : _size.text.trim(),
      weightG: _weight.text.trim().isEmpty ? null : double.tryParse(_weight.text.replaceAll(',', '.')),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      rating: _rating,
      bestSeason: _season,
      bestWeather: _weather,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (_isEditing) {
      await _repo.update(bait);
    } else {
      await _repo.insert(bait);
    }
    if (mounted) {
      context.read<AppDataBus>().notifyChanged();
      Navigator.of(context).pop(bait);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать приманку' : 'Новая приманка')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PhotoPickerField(photoPaths: _photos, onChanged: (v) => setState(() => _photos = v)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название приманки *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _brand, decoration: const InputDecoration(labelText: 'Бренд'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _type, decoration: const InputDecoration(labelText: 'Тип'))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _color, decoration: const InputDecoration(labelText: 'Цвет'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _size, decoration: const InputDecoration(labelText: 'Размер'))),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _weight,
              decoration: const InputDecoration(labelText: 'Вес, г'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _season,
              decoration: const InputDecoration(labelText: 'Лучший сезон'),
              items: SeasonOptions.all.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _season = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: _weather,
              decoration: const InputDecoration(labelText: 'Лучшая погода'),
              onChanged: (v) => _weather = v,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Заметки'),
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Рейтинг:'),
                const SizedBox(width: 10),
                RatingStars(rating: _rating, onChanged: (v) => setState(() => _rating = v)),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Сохранить изменения' : 'Добавить приманку'),
            ),
          ],
        ),
      ),
    );
  }
}
