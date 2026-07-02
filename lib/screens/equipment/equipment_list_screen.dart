import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/equipment_item.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../providers/app_data_bus.dart';
import 'equipment_form_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _repo = EquipmentRepository();
  List<EquipmentItem> _items = [];
  bool _loading = true;
  String? _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.getAll(query: _query, category: _category);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _delete(EquipmentItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить снаряжение?'),
        content: Text('Запись «${item.name}» будет удалена.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.delete(item.id);
      if (mounted) context.read<AppDataBus>().notifyChanged();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Снаряжение')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => EquipmentFormScreen(initialCategory: _category)));
          _load();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Поиск по названию', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) {
                _query = v;
                _load();
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _categoryChip(null, 'Все'),
                ...EquipmentCategory.all.map((c) => _categoryChip(c, EquipmentCategory.label(c))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.handyman_rounded,
                        title: 'Пока нет снаряжения',
                        message: 'Добавьте удилища, катушки, лески и другое снаряжение.',
                        actionLabel: 'Добавить снаряжение',
                        onAction: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const EquipmentFormScreen()));
                          _load();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                  backgroundImage: item.photoPaths.isNotEmpty ? FileImage(File(item.photoPaths.first)) : null,
                                  child: item.photoPaths.isEmpty ? const Icon(Icons.handyman_rounded) : null,
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('${EquipmentCategory.label(item.category)}'
                                    '${item.brand != null ? ' · ${item.brand}' : ''}'),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => EquipmentFormScreen(existing: item)),
                                      );
                                      _load();
                                    } else if (v == 'delete') {
                                      _delete(item);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                                    PopupMenuItem(value: 'delete', child: Text('Удалить')),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => EquipmentFormScreen(existing: item)),
                                  );
                                  _load();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _category = value);
          _load();
        },
      ),
    );
  }
}
