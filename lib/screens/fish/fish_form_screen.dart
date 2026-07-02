import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../data/models/fish.dart';
import '../../data/repositories/fish_repository.dart';
import '../../providers/app_data_bus.dart';

class FishFormScreen extends StatefulWidget {
  final Fish? existing;

  const FishFormScreen({super.key, this.existing});

  @override
  State<FishFormScreen> createState() => _FishFormScreenState();
}

class _FishFormScreenState extends State<FishFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FishRepository();

  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _averageSize;
  late final TextEditingController _recordWeight;
  late final TextEditingController _recordLength;
  late final TextEditingController _color;
  late final TextEditingController _habitat;
  late final TextEditingController _customNotes;
  String? _category;
  List<String> _photos = [];
  bool _favorite = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    _name = TextEditingController(text: f?.name ?? '');
    _notes = TextEditingController(text: f?.notes ?? '');
    _averageSize = TextEditingController(text: f?.averageSizeCm?.toString() ?? '');
    _recordWeight = TextEditingController(text: f?.recordWeightKg?.toString() ?? '');
    _recordLength = TextEditingController(text: f?.recordLengthCm?.toString() ?? '');
    _color = TextEditingController(text: f?.color ?? '');
    _habitat = TextEditingController(text: f?.habitatNotes ?? '');
    _customNotes = TextEditingController(text: f?.customNotes ?? '');
    _category = f?.category;
    _photos = List.of(f?.photoPaths ?? []);
    _favorite = f?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _averageSize.dispose();
    _recordWeight.dispose();
    _recordLength.dispose();
    _color.dispose();
    _habitat.dispose();
    _customNotes.dispose();
    super.dispose();
  }

  double? _parse(String text) => text.trim().isEmpty ? null : double.tryParse(text.replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final fish = Fish(
      id: widget.existing?.id ?? IdGenerator.next(),
      name: _name.text.trim(),
      category: _category,
      photoPaths: _photos,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      averageSizeCm: _parse(_averageSize.text),
      recordWeightKg: _parse(_recordWeight.text),
      recordLengthCm: _parse(_recordLength.text),
      color: _color.text.trim().isEmpty ? null : _color.text.trim(),
      habitatNotes: _habitat.text.trim().isEmpty ? null : _habitat.text.trim(),
      customNotes: _customNotes.text.trim().isEmpty ? null : _customNotes.text.trim(),
      isFavorite: _favorite,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      await _repo.update(fish);
    } else {
      await _repo.insert(fish);
    }

    if (mounted) {
      context.read<AppDataBus>().notifyChanged();
      Navigator.of(context).pop(fish);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать рыбу' : 'Новая рыба')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PhotoPickerField(photoPaths: _photos, onChanged: (v) => setState(() => _photos = v)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название рыбы *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: FishCategories.defaults
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _averageSize,
                    decoration: const InputDecoration(labelText: 'Средний размер, см'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _color,
                    decoration: const InputDecoration(labelText: 'Окрас'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recordWeight,
                    decoration: const InputDecoration(labelText: 'Личный рекорд, кг'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _recordLength,
                    decoration: const InputDecoration(labelText: 'Рекорд длины, см'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _habitat,
              decoration: const InputDecoration(labelText: 'Особенности среды обитания'),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Любимая приманка (заметка)'),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _customNotes,
              decoration: const InputDecoration(labelText: 'Дополнительные заметки'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Избранная рыба'),
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Сохранить изменения' : 'Добавить рыбу'),
            ),
          ],
        ),
      ),
    );
  }
}
