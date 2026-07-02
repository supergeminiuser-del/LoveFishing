import 'package:flutter/material.dart';

import '../../data/models/bait.dart';
import '../../data/models/equipment_item.dart';
import '../../data/models/fish.dart';
import '../../data/models/fishing_spot.dart';
import '../../data/models/fishing_trip.dart';
import '../../data/repositories/bait_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/fish_repository.dart';
import '../../data/repositories/spot_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../baits/bait_form_screen.dart';
import '../equipment/equipment_form_screen.dart';
import '../fish/fish_form_screen.dart';
import '../spots/spot_form_screen.dart';
import '../trips/trip_detail_screen.dart';

/// Единый поиск по рыбам, приманкам, снаряжению, местам и рыбалкам.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _fishRepo = FishRepository();
  final _baitRepo = BaitRepository();
  final _equipRepo = EquipmentRepository();
  final _spotRepo = SpotRepository();
  final _tripRepo = TripRepository();

  List<Fish> _fish = [];
  List<Bait> _baits = [];
  List<EquipmentItem> _equipment = [];
  List<FishingSpot> _spots = [];
  List<FishingTrip> _trips = [];
  bool _searched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _fish = [];
        _baits = [];
        _equipment = [];
        _spots = [];
        _trips = [];
        _searched = false;
      });
      return;
    }
    final fish = await _fishRepo.getAll(query: query);
    final baits = await _baitRepo.getAll(query: query);
    final equipment = await _equipRepo.getAll(query: query);
    final spots = await _spotRepo.getAll(query: query);
    final trips = await _tripRepo.getAll(query: query);
    if (mounted) {
      setState(() {
        _fish = fish;
        _baits = baits;
        _equipment = equipment;
        _spots = spots;
        _trips = trips;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalResults = _fish.length + _baits.length + _equipment.length + _spots.length + _trips.length;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск по всему приложению',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: !_searched
          ? Center(
              child: Text('Введите запрос для поиска рыб, приманок,\nснаряжения, мест и рыбалок',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            )
          : totalResults == 0
              ? Center(child: Text('Ничего не найдено', style: theme.textTheme.bodyMedium))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_fish.isNotEmpty) _group('Рыбы', _fish.map((f) => ListTile(
                          leading: const Icon(Icons.set_meal_rounded),
                          title: Text(f.name),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FishFormScreen(existing: f))),
                        ))),
                    if (_baits.isNotEmpty) _group('Приманки', _baits.map((b) => ListTile(
                          leading: const Icon(Icons.bubble_chart_rounded),
                          title: Text(b.name),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BaitFormScreen(existing: b))),
                        ))),
                    if (_equipment.isNotEmpty) _group('Снаряжение', _equipment.map((e) => ListTile(
                          leading: const Icon(Icons.handyman_rounded),
                          title: Text(e.name),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EquipmentFormScreen(existing: e))),
                        ))),
                    if (_spots.isNotEmpty) _group('Места', _spots.map((s) => ListTile(
                          leading: const Icon(Icons.place_rounded),
                          title: Text(s.name),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SpotFormScreen(existing: s))),
                        ))),
                    if (_trips.isNotEmpty) _group('Рыбалки', _trips.map((t) => ListTile(
                          leading: const Icon(Icons.directions_boat_filled_rounded),
                          title: Text(t.title ?? 'Рыбалка'),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: t))),
                        ))),
                  ],
                ),
    );
  }

  Widget _group(String title, Iterable<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        Card(child: Column(children: children.toList())),
        const SizedBox(height: 12),
      ],
    );
  }
}
