import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../core/widgets/photo_picker_field.dart';
import '../../data/models/equipment_item.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../providers/app_data_bus.dart';

class EquipmentFormScreen extends StatefulWidget {
  final EquipmentItem? existing;
  final String? initialCategory;

  const EquipmentFormScreen({super.key, this.existing, this.initialCategory});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = EquipmentRepository();

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _notes;
  late String _category;
  DateTime? _purchaseDate;
  List<String> _photos = [];
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _brand = TextEditingController(text: e?.brand ?? '');
    _model = TextEditingController(text: e?.model ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? widget.initialCategory ?? EquipmentCategory.rod;
    _purchaseDate = e?.purchaseDate;
    _photos = List.of(e?.photoPaths ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final item = EquipmentItem(
      id: widget.existing?.id ?? IdGenerator.next(),
      name: _name.text.trim(),
      category: _category,
      photoPaths: _photos,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      model: _model.text.trim().isEmpty ? null : _model.text.trim(),
      purchaseDate: _purchaseDate,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (_isEditing) {
      await _repo.update(item);
    } else {
      await _repo.insert(item);
    }
    if (mounted) {
      context.read<AppDataBus>().notifyChanged();
      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать снаряжение' : 'Новое снаряжение')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PhotoPickerField(photoPaths: _photos, onChanged: (v) => setState(() => _photos = v)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Категория *'),
              items: EquipmentCategory.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(EquipmentCategory.label(c))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _brand, decoration: const InputDecoration(labelText: 'Бренд'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _model, decoration: const InputDecoration(labelText: 'Модель'))),
            ]),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded),
              label: Text(_purchaseDate == null ? 'Дата покупки не указана' : 'Куплено: ${_purchaseDate!.day}.${_purchaseDate!.month}.${_purchaseDate!.year}'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Заметки'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Сохранить изменения' : 'Добавить снаряжение'),
            ),
          ],
        ),
      ),
    );
  }
}
