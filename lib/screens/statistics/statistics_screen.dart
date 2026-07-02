import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  final _service = StatisticsService();
  FullStatistics? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final stats = await _service.loadFullStatistics();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_stats == null || _stats!.totalCatches == 0)
              ? const EmptyState(
                  icon: Icons.query_stats_rounded,
                  title: 'Пока нет данных',
                  message: 'Добавьте уловы, чтобы увидеть статистику и графики.',
                )
              : RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          StatCard(label: 'Всего уловов', value: '${_stats!.totalCatches}', icon: Icons.set_meal_rounded),
                          StatCard(label: 'Рыбалок', value: '${_stats!.totalTrips}', icon: Icons.directions_boat_filled_rounded, accentColor: Theme.of(context).colorScheme.secondary),
                          StatCard(label: 'Средний вес', value: AppFormatters.weight(_stats!.averageWeightKg), icon: Icons.scale_rounded),
                          StatCard(
                            label: 'Самый крупный',
                            value: AppFormatters.weight(_stats!.biggestCatch?.weightKg),
                            subtitle: _stats!.biggestCatchFish?.name,
                            icon: Icons.emoji_events_rounded,
                            accentColor: Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_stats!.catchesByMonth.isNotEmpty) ...[
                        const SectionHeader(title: 'Уловы по месяцам'),
                        SizedBox(height: 200, child: _MonthlyBarChart(data: _stats!.catchesByMonth)),
                        const SizedBox(height: 28),
                      ],
                      if (_stats!.catchesByFish.isNotEmpty) ...[
                        const SectionHeader(title: 'По видам рыбы'),
                        ..._stats!.catchesByFish.take(8).map((e) => _barRow(e.name, e.count, _stats!.catchesByFish.first.count, theme.colorScheme.primary)),
                        const SizedBox(height: 24),
                      ],
                      if (_stats!.catchesByBait.isNotEmpty) ...[
                        const SectionHeader(title: 'По приманкам'),
                        ..._stats!.catchesByBait.take(8).map((e) => _barRow(e.name, e.count, _stats!.catchesByBait.first.count, theme.colorScheme.secondary)),
                        const SizedBox(height: 24),
                      ],
                      if (_stats!.catchesBySpot.isNotEmpty) ...[
                        const SectionHeader(title: 'По местам ловли'),
                        ..._stats!.catchesBySpot.take(8).map((e) => _barRow(e.name, e.count, _stats!.catchesBySpot.first.count, Colors.amber)),
                        const SizedBox(height: 24),
                      ],
                      if (_stats!.personalRecords.isNotEmpty) ...[
                        const SectionHeader(title: 'Личные рекорды'),
                        ..._stats!.personalRecords.map((r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                                title: Text(r.fish.name),
                                subtitle: Text('${AppFormatters.weight(r.maxWeightKg)} · ${AppFormatters.length(r.maxLengthCm)}'),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _barRow(String label, int value, int max, Color color) {
    final ratio = max == 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 14,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<MapEntry<String, int>> data;

  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].value.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                final parts = data[idx].key.split('-');
                final label = parts.length == 2 ? parts[1] : data[idx].key;
                return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 10)));
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
