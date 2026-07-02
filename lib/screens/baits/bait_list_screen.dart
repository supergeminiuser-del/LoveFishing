import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/rating_stars.dart';
import '../../data/models/bait.dart';
import '../../data/repositories/bait_repository.dart';
import '../../providers/app_data_bus.dart';
import 'bait_form_screen.dart';

class BaitListScreen extends StatefulWidget {
  const BaitListScreen({super.key});

  @override
  State<BaitListScreen> createState() => _BaitListScreenState();
}

class _BaitListScreenState extends State<BaitListScreen> {
  final _repo = BaitRepository();
  List<Bait> _items = [];
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

  Future<void> _delete(Bait bait) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить приманку?'),
        content: Text('Запись «${bait.name}» будет удалена.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.delete(bait.id);
      if (mounted) context.read<AppDataBus>().notifyChanged();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Приманки')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BaitFormScreen()));
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
                        icon: Icons.bubble_chart_rounded,
                        title: 'Пока нет приманок',
                        message: 'Добавьте приманки, чтобы указывать их при записи улова.',
                        actionLabel: 'Добавить приманку',
                        onAction: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const BaitFormScreen()));
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
                            final bait = _items[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.14),
                                  backgroundImage: bait.photoPaths.isNotEmpty ? FileImage(File(bait.photoPaths.first)) : null,
                                  child: bait.photoPaths.isEmpty ? const Icon(Icons.bubble_chart_rounded) : null,
                                ),
                                title: Text(bait.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text([bait.brand, bait.type].where((e) => e != null && e.isNotEmpty).join(' · ')),
                                trailing: SizedBox(
                                  width: 90,
                                  child: RatingStars(rating: bait.rating, size: 14),
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => BaitFormScreen(existing: bait)),
                                  );
                                  _load();
                                },
                                onLongPress: () => _delete(bait),
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
