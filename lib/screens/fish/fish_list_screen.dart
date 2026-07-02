import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../data/models/fish.dart';
import '../../data/repositories/fish_repository.dart';
import '../../providers/app_data_bus.dart';
import 'fish_form_screen.dart';

class FishListScreen extends StatefulWidget {
  const FishListScreen({super.key});

  @override
  State<FishListScreen> createState() => _FishListScreenState();
}

class _FishListScreenState extends State<FishListScreen> {
  final _repo = FishRepository();
  List<Fish> _items = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.getAll(query: _query);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _delete(Fish fish) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить рыбу?'),
        content: Text('Запись «${fish.name}» будет удалена без возможности восстановления.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.delete(fish.id);
      if (mounted) context.read<AppDataBus>().notifyChanged();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рыбы')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FishFormScreen()));
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.set_meal_rounded,
                        title: 'Пока нет рыб',
                        message: 'Добавьте виды рыб, чтобы использовать их в уловах и статистике.',
                        actionLabel: 'Добавить рыбу',
                        onAction: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const FishFormScreen()));
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
                            final fish = _items[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                  backgroundImage: fish.photoPaths.isNotEmpty ? FileImage(File(fish.photoPaths.first)) : null,
                                  child: fish.photoPaths.isEmpty
                                      ? const Icon(Icons.set_meal_rounded)
                                      : null,
                                ),
                                title: Text(fish.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(fish.category ?? 'Без категории'),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => FishFormScreen(existing: fish)),
                                      );
                                      _load();
                                    } else if (v == 'delete') {
                                      _delete(fish);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                                    PopupMenuItem(value: 'delete', child: Text('Удалить')),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => FishFormScreen(existing: fish)),
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
}
