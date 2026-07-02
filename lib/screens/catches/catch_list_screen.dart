import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/catch_record.dart';
import '../../data/repositories/catch_repository.dart';
import '../../data/repositories/fish_repository.dart';
import 'catch_detail_screen.dart';
import 'catch_form_screen.dart';

class CatchListScreen extends StatefulWidget {
  const CatchListScreen({super.key});

  @override
  State<CatchListScreen> createState() => CatchListScreenState();
}

class CatchListScreenState extends State<CatchListScreen> {
  final _repo = CatchRepository();
  final _fishRepo = FishRepository();
  List<CatchRecord> _items = [];
  Map<String, String> _fishNames = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final items = await _repo.getAll(filter: CatchFilter(query: _query));
    final fishIds = items.map((c) => c.fishId).whereType<String>().toSet().toList();
    final fishList = await _fishRepo.getByIds(fishIds);
    if (mounted) {
      setState(() {
        _items = items;
        _fishNames = {for (final f in fishList) f.id: f.name};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Поиск по заметкам, погоде...', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) {
                _query = v;
                reload();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? EmptyState(
                        icon: Icons.set_meal_rounded,
                        title: 'Пока нет уловов',
                        message: 'Добавьте первый улов — это займёт меньше 30 секунд.',
                        actionLabel: 'Добавить улов',
                        onAction: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatchFormScreen()));
                          reload();
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: reload,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = _items[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.set_meal_rounded),
                                ),
                                title: Text(_fishNames[c.fishId] ?? 'Без вида рыбы', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('${AppFormatters.relative(c.date)} · ${AppFormatters.weight(c.weightKg)} · ${AppFormatters.length(c.lengthCm)}'),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () async {
                                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: c.id)));
                                  reload();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'catch_fab',
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatchFormScreen()));
          reload();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Улов'),
      ),
    );
  }
}
