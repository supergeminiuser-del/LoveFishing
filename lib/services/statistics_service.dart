import '../data/models/catch_record.dart';
import '../data/models/fish.dart';
import '../data/repositories/bait_repository.dart';
import '../data/repositories/catch_repository.dart';
import '../data/repositories/fish_repository.dart';
import '../data/repositories/spot_repository.dart';
import '../data/repositories/trip_repository.dart';

class NamedCount {
  final String id;
  final String name;
  final int count;

  const NamedCount({required this.id, required this.name, required this.count});
}

class PersonalRecord {
  final Fish fish;
  final double? maxWeightKg;
  final double? maxLengthCm;

  const PersonalRecord({required this.fish, this.maxWeightKg, this.maxLengthCm});
}

class DashboardStats {
  final int totalCatches;
  final int totalTrips;
  final String? favoriteSpotName;
  final CatchRecord? biggestCatch;
  final Fish? biggestCatchFish;
  final String? mostSuccessfulBaitName;
  final List<CatchRecord> recentCatches;
  final List<PersonalRecord> personalRecords;

  const DashboardStats({
    required this.totalCatches,
    required this.totalTrips,
    this.favoriteSpotName,
    this.biggestCatch,
    this.biggestCatchFish,
    this.mostSuccessfulBaitName,
    this.recentCatches = const [],
    this.personalRecords = const [],
  });

  static const empty = DashboardStats(totalCatches: 0, totalTrips: 0);
}

class FullStatistics {
  final int totalCatches;
  final int totalTrips;
  final double? averageWeightKg;
  final CatchRecord? biggestCatch;
  final Fish? biggestCatchFish;
  final List<MapEntry<String, int>> catchesByMonth; // key = 'YYYY-MM'
  final List<MapEntry<String, int>> catchesByYear;
  final List<NamedCount> catchesByFish;
  final List<NamedCount> catchesByBait;
  final List<NamedCount> catchesBySpot;
  final List<MapEntry<String, int>> tripsPerMonth;
  final List<PersonalRecord> personalRecords;

  const FullStatistics({
    this.totalCatches = 0,
    this.totalTrips = 0,
    this.averageWeightKg,
    this.biggestCatch,
    this.biggestCatchFish,
    this.catchesByMonth = const [],
    this.catchesByYear = const [],
    this.catchesByFish = const [],
    this.catchesByBait = const [],
    this.catchesBySpot = const [],
    this.tripsPerMonth = const [],
    this.personalRecords = const [],
  });
}

/// Расчёт всей статистики приложения на основе локальных данных.
/// Все агрегаты считаются по требованию — при 10 000+ уловов операции
/// выполняются за счёт индексированных SQL-запросов в репозиториях.
class StatisticsService {
  final CatchRepository _catches = CatchRepository();
  final FishRepository _fish = FishRepository();
  final BaitRepository _baits = BaitRepository();
  final SpotRepository _spots = SpotRepository();
  final TripRepository _trips = TripRepository();

  Future<DashboardStats> loadDashboard() async {
    final totalCatches = await _catches.count();
    final totalTrips = await _trips.count();

    String? favoriteSpotName;
    final mostVisitedSpotId = await _catches.getMostVisitedSpotId();
    if (mostVisitedSpotId != null) {
      final spot = await _spots.getById(mostVisitedSpotId);
      favoriteSpotName = spot?.name;
    }

    final biggestCatch = await _catches.getBiggestCatch();
    Fish? biggestCatchFish;
    if (biggestCatch?.fishId != null) {
      biggestCatchFish = await _fish.getById(biggestCatch!.fishId!);
    }

    String? mostSuccessfulBaitName;
    final baitId = await _catches.getMostSuccessfulBaitId();
    if (baitId != null) {
      final bait = await _baits.getById(baitId);
      mostSuccessfulBaitName = bait?.name;
    }

    final recentCatches = await _catches.getRecent(limit: 5);
    final personalRecords = await _loadPersonalRecords(limit: 5);

    return DashboardStats(
      totalCatches: totalCatches,
      totalTrips: totalTrips,
      favoriteSpotName: favoriteSpotName,
      biggestCatch: biggestCatch,
      biggestCatchFish: biggestCatchFish,
      mostSuccessfulBaitName: mostSuccessfulBaitName,
      recentCatches: recentCatches,
      personalRecords: personalRecords,
    );
  }

  Future<List<PersonalRecord>> _loadPersonalRecords({int? limit}) async {
    final raw = await _catches.personalRecordsByFish();
    final fishIds = raw.map((e) => e['fish_id'] as String).toList();
    final fishList = await _fish.getByIds(fishIds);
    final fishById = {for (final f in fishList) f.id: f};

    final records = <PersonalRecord>[];
    for (final row in raw) {
      final fish = fishById[row['fish_id']];
      if (fish == null) continue;
      records.add(PersonalRecord(
        fish: fish,
        maxWeightKg: (row['max_weight'] as num?)?.toDouble(),
        maxLengthCm: (row['max_length'] as num?)?.toDouble(),
      ));
    }
    records.sort((a, b) => (b.maxWeightKg ?? 0).compareTo(a.maxWeightKg ?? 0));
    if (limit != null && records.length > limit) {
      return records.sublist(0, limit);
    }
    return records;
  }

  Future<FullStatistics> loadFullStatistics() async {
    final totalCatches = await _catches.count();
    final totalTrips = await _trips.count();
    final averageWeight = await _catches.getAverageWeight();
    final biggestCatch = await _catches.getBiggestCatch();
    Fish? biggestCatchFish;
    if (biggestCatch?.fishId != null) {
      biggestCatchFish = await _fish.getById(biggestCatch!.fishId!);
    }

    final byMonthRaw = await _catches.countByMonth(monthsBack: 12);
    final catchesByMonth = byMonthRaw
        .map((e) => MapEntry(e['ym'] as String, (e['c'] as int?) ?? 0))
        .toList()
        .reversed
        .toList();

    final byYearRaw = await _catches.countByYear();
    final catchesByYear =
        byYearRaw.map((e) => MapEntry(e['y'] as String, (e['c'] as int?) ?? 0)).toList();

    final byFishRaw = await _catches.countByFish();
    final fishIds = byFishRaw.map((e) => e['fish_id'] as String).toList();
    final fishList = await _fish.getByIds(fishIds);
    final fishById = {for (final f in fishList) f.id: f};
    final catchesByFish = byFishRaw
        .map((e) => NamedCount(
              id: e['fish_id'] as String,
              name: fishById[e['fish_id']]?.name ?? 'Неизвестно',
              count: (e['c'] as int?) ?? 0,
            ))
        .toList();

    final byBaitRaw = await _catches.countByBait();
    final baitIds = byBaitRaw.map((e) => e['bait_id'] as String).toList();
    final baitList = await _baits.getByIds(baitIds);
    final baitById = {for (final b in baitList) b.id: b};
    final catchesByBait = byBaitRaw
        .map((e) => NamedCount(
              id: e['bait_id'] as String,
              name: baitById[e['bait_id']]?.name ?? 'Неизвестно',
              count: (e['c'] as int?) ?? 0,
            ))
        .toList();

    final bySpotRaw = await _catches.countBySpot();
    final spotIds = bySpotRaw.map((e) => e['spot_id'] as String).toList();
    final spotList = await Future.wait(spotIds.map((id) => _spots.getById(id)));
    final spotById = {
      for (final s in spotList)
        if (s != null) s.id: s,
    };
    final catchesBySpot = bySpotRaw
        .map((e) => NamedCount(
              id: e['spot_id'] as String,
              name: spotById[e['spot_id']]?.name ?? 'Неизвестно',
              count: (e['c'] as int?) ?? 0,
            ))
        .toList();

    final trips = await _trips.getAll();
    final tripsByMonth = <String, int>{};
    for (final t in trips) {
      final key =
          '${t.startDate.year}-${t.startDate.month.toString().padLeft(2, '0')}';
      tripsByMonth[key] = (tripsByMonth[key] ?? 0) + 1;
    }
    final tripsPerMonth = tripsByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final personalRecords = await _loadPersonalRecords();

    return FullStatistics(
      totalCatches: totalCatches,
      totalTrips: totalTrips,
      averageWeightKg: averageWeight,
      biggestCatch: biggestCatch,
      biggestCatchFish: biggestCatchFish,
      catchesByMonth: catchesByMonth,
      catchesByYear: catchesByYear,
      catchesByFish: catchesByFish,
      catchesByBait: catchesByBait,
      catchesBySpot: catchesBySpot,
      tripsPerMonth: tripsPerMonth,
      personalRecords: personalRecords,
    );
  }
}
