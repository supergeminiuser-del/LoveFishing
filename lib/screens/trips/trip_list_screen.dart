import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/fishing_trip.dart';
import '../../data/repositories/trip_repository.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final _repo = TripRepository();
  List<FishingTrip> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.getAll();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyState(
                  icon: Icons.directions_boat_filled_rounded,
                  title: 'Пока нет рыбалок',
                  message: 'Группируйте уловы по рыбалкам, чтобы отслеживать поездки.',
                  actionLabel: 'Начать рыбалку',
                  onAction: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripFormScreen()));
                    _load();
                  },
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final trip = _items[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                            child: const Icon(Icons.directions_boat_filled_rounded),
                          ),
                          title: Text(trip.title ?? AppFormatters.dateFull(trip.startDate),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(trip.isOngoing
                              ? 'Началась ${AppFormatters.dateShort(trip.startDate)} · продолжается'
                              : '${AppFormatters.dateShort(trip.startDate)} — ${AppFormatters.dateShort(trip.endDate!)}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            await Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'trip_fab',
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripFormScreen()));
          _load();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Рыбалка'),
      ),
    );
  }
}
