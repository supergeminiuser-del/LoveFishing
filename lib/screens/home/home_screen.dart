import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/fish.dart';
import '../../data/repositories/fish_repository.dart';
import '../../providers/app_data_bus.dart';
import '../../services/statistics_service.dart';
import '../catches/catch_detail_screen.dart';
import '../catches/catch_form_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _service = StatisticsService();
  final _fishRepo = FishRepository();
  DashboardStats? _stats;
  Map<String, Fish> _fishById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final stats = await _service.loadDashboard();
    final fishIds = stats.recentCatches.map((c) => c.fishId).whereType<String>().toSet().toList();
    final fishList = await _fishRepo.getByIds(fishIds);
    if (mounted) {
      setState(() {
        _stats = stats;
        _fishById = {for (final f in fishList) f.id: f};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _stats ?? DashboardStats.empty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FishLog Russia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(label: 'Всего уловов', value: '${stats.totalCatches}', icon: Icons.set_meal_rounded),
                      StatCard(label: 'Рыбалок', value: '${stats.totalTrips}', icon: Icons.directions_boat_filled_rounded, accentColor: theme.colorScheme.secondary),
                      StatCard(
                        label: 'Любимое место',
                        value: stats.favoriteSpotName ?? '—',
                        icon: Icons.place_rounded,
                        accentColor: Colors.amber,
                      ),
                      StatCard(
                        label: 'Лучшая приманка',
                        value: stats.mostSuccessfulBaitName ?? '—',
                        icon: Icons.bubble_chart_rounded,
                        accentColor: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, color: theme.colorScheme.primary, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Самый крупный улов', style: TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  stats.biggestCatch != null
                                      ? '${stats.biggestCatchFish?.name ?? 'Рыба'} · ${AppFormatters.weight(stats.biggestCatch!.weightKg)}'
                                      : 'Пока нет данных',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Личные рекорды',
                    actionLabel: stats.personalRecords.isNotEmpty ? 'Все' : null,
                  ),
                  if (stats.personalRecords.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Записей пока нет', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    )
                  else
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: stats.personalRecords.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final r = stats.personalRecords[index];
                          return Container(
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.fish.name, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Text(AppFormatters.weight(r.maxWeightKg), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                Text(AppFormatters.length(r.maxLengthCm), style: theme.textTheme.bodySmall),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Последние уловы'),
                  if (stats.recentCatches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Пока нет уловов', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    )
                  else
                    ...stats.recentCatches.map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              child: const Icon(Icons.set_meal_rounded),
                            ),
                            title: Text(_fishById[c.fishId]?.name ?? 'Без вида рыбы'),
                            subtitle: Text('${AppFormatters.relative(c.date)} · ${AppFormatters.weight(c.weightKg)}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CatchDetailScreen(catchId: c.id)));
                              reload();
                            },
                          ),
                        )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_add_catch_fab',
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatchFormScreen()));
          if (context.mounted) context.read<AppDataBus>().notifyChanged();
          reload();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить улов'),
      ),
    );
  }
}
