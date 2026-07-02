import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/fishing_spot.dart';
import '../../data/repositories/spot_repository.dart';
import '../../providers/app_data_bus.dart';
import 'spot_form_screen.dart';

class SpotListScreen extends StatefulWidget {
  const SpotListScreen({super.key});

  @override
  State<SpotListScreen> createState() => _SpotListScreenState();
}

class _SpotListScreenState extends State<SpotListScreen> {
  final _repo = SpotRepository();
  List<FishingSpot> _items = [];
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

  Future<void> _delete(FishingSpot spot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить место?'),
        content: Text('Метка «${spot.name}» будет удалена.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.delete(spot.id);
      if (mounted) context.read<AppDataBus>().notifyChanged();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Места')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpotFormScreen()));
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
                        icon: Icons.place_rounded,
                        title: 'Пока нет мест',
                        message: 'Добавляйте места на карте или здесь вручную.',
                        actionLabel: 'Добавить место',
                        onAction: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const SpotFormScreen()));
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
                            final spot = _items[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: Icon(
                                  spot.markerType == 'danger' ? Icons.warning_amber_rounded : Icons.place_rounded,
                                  color: spot.isFavorite ? Colors.amber : Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(AppFormatters.coordinates(spot.latitude, spot.longitude)),
                                trailing: spot.isFavorite ? const Icon(Icons.star_rounded, color: Colors.amber) : null,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => SpotFormScreen(existing: spot)),
                                  );
                                  _load();
                                },
                                onLongPress: () => _delete(spot),
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
