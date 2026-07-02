import '../database/app_database.dart';
import '../models/catch_record.dart';

class CatchFilter {
  final String? fishId;
  final String? baitId;
  final String? spotId;
  final String? tripId;
  final DateTime? from;
  final DateTime? to;
  final String? query;
  final int? minRating;

  const CatchFilter({
    this.fishId,
    this.baitId,
    this.spotId,
    this.tripId,
    this.from,
    this.to,
    this.query,
    this.minRating,
  });

  bool get isEmpty =>
      fishId == null &&
      baitId == null &&
      spotId == null &&
      tripId == null &&
      from == null &&
      to == null &&
      (query == null || query!.trim().isEmpty) &&
      minRating == null;
}

class CatchRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<CatchRecord>> getAll({
    CatchFilter filter = const CatchFilter(),
    int? limit,
    int? offset,
  }) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <Object?>[];

    if (filter.fishId != null) {
      conditions.add('fish_id = ?');
      args.add(filter.fishId);
    }
    if (filter.baitId != null) {
      conditions.add('bait_id = ?');
      args.add(filter.baitId);
    }
    if (filter.spotId != null) {
      conditions.add('spot_id = ?');
      args.add(filter.spotId);
    }
    if (filter.tripId != null) {
      conditions.add('trip_id = ?');
      args.add(filter.tripId);
    }
    if (filter.from != null) {
      conditions.add('date >= ?');
      args.add(filter.from!.toIso8601String());
    }
    if (filter.to != null) {
      conditions.add('date <= ?');
      args.add(filter.to!.toIso8601String());
    }
    if (filter.minRating != null) {
      conditions.add('rating >= ?');
      args.add(filter.minRating);
    }
    if (filter.query != null && filter.query!.trim().isNotEmpty) {
      conditions.add('(notes LIKE ? OR weather_text LIKE ? OR method LIKE ?)');
      final q = '%${filter.query!.trim()}%';
      args.addAll([q, q, q]);
    }

    final rows = await db.query(
      'catches',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(CatchRecord.fromMap).toList();
  }

  Future<CatchRecord?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('catches', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return CatchRecord.fromMap(rows.first);
  }

  Future<List<CatchRecord>> getForSpot(String spotId) async {
    final db = await _db.database;
    final rows = await db.query('catches', where: 'spot_id = ?', whereArgs: [spotId], orderBy: 'date DESC');
    return rows.map(CatchRecord.fromMap).toList();
  }

  Future<List<CatchRecord>> getForTrip(String tripId) async {
    final db = await _db.database;
    final rows = await db.query('catches', where: 'trip_id = ?', whereArgs: [tripId], orderBy: 'date DESC');
    return rows.map(CatchRecord.fromMap).toList();
  }

  Future<void> insert(CatchRecord record) async {
    final db = await _db.database;
    await db.insert('catches', record.toMap());
  }

  Future<void> update(CatchRecord record) async {
    final db = await _db.database;
    await db.update('catches', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('catches', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(quantity),0) AS c FROM catches');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<CatchRecord?> getBiggestCatch() async {
    final db = await _db.database;
    final rows = await db.query(
      'catches',
      where: 'weight_kg IS NOT NULL',
      orderBy: 'weight_kg DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CatchRecord.fromMap(rows.first);
  }

  Future<double?> getAverageWeight() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT AVG(weight_kg) as avg FROM catches WHERE weight_kg IS NOT NULL');
    return (rows.first['avg'] as num?)?.toDouble();
  }

  /// ID приманки с наибольшим числом уловов.
  Future<String?> getMostSuccessfulBaitId() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT bait_id, COUNT(*) as c FROM catches
      WHERE bait_id IS NOT NULL GROUP BY bait_id ORDER BY c DESC LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return rows.first['bait_id'] as String?;
  }

  Future<String?> getMostVisitedSpotId() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT spot_id, COUNT(*) as c FROM catches
      WHERE spot_id IS NOT NULL GROUP BY spot_id ORDER BY c DESC LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return rows.first['spot_id'] as String?;
  }

  Future<List<Map<String, Object?>>> countByMonth({int monthsBack = 12}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT strftime('%Y-%m', date) as ym, COALESCE(SUM(quantity),0) as c
      FROM catches GROUP BY ym ORDER BY ym DESC LIMIT ?
    ''', [monthsBack]);
    return rows;
  }

  Future<List<Map<String, Object?>>> countByYear() async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT strftime('%Y', date) as y, COALESCE(SUM(quantity),0) as c
      FROM catches GROUP BY y ORDER BY y ASC
    ''');
  }

  Future<List<Map<String, Object?>>> countByFish() async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT fish_id, COALESCE(SUM(quantity),0) as c FROM catches
      WHERE fish_id IS NOT NULL GROUP BY fish_id ORDER BY c DESC
    ''');
  }

  Future<List<Map<String, Object?>>> countBySpot() async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT spot_id, COALESCE(SUM(quantity),0) as c FROM catches
      WHERE spot_id IS NOT NULL GROUP BY spot_id ORDER BY c DESC
    ''');
  }

  Future<List<Map<String, Object?>>> countByBait() async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT bait_id, COALESCE(SUM(quantity),0) as c FROM catches
      WHERE bait_id IS NOT NULL GROUP BY bait_id ORDER BY c DESC
    ''');
  }

  /// Личные рекорды: наибольший вес по каждому виду рыбы.
  Future<List<Map<String, Object?>>> personalRecordsByFish() async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT fish_id, MAX(weight_kg) as max_weight, MAX(length_cm) as max_length
      FROM catches WHERE fish_id IS NOT NULL GROUP BY fish_id
    ''');
  }

  /// Лучшая приманка для конкретного вида рыбы.
  Future<String?> bestBaitForFish(String fishId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT bait_id, COUNT(*) as c FROM catches
      WHERE fish_id = ? AND bait_id IS NOT NULL GROUP BY bait_id ORDER BY c DESC LIMIT 1
    ''', [fishId]);
    if (rows.isEmpty) return null;
    return rows.first['bait_id'] as String?;
  }

  /// Лучшая приманка для конкретного места.
  Future<String?> bestBaitForSpot(String spotId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT bait_id, COUNT(*) as c FROM catches
      WHERE spot_id = ? AND bait_id IS NOT NULL GROUP BY bait_id ORDER BY c DESC LIMIT 1
    ''', [spotId]);
    if (rows.isEmpty) return null;
    return rows.first['bait_id'] as String?;
  }

  Future<List<CatchRecord>> getRecent({int limit = 5}) async {
    final db = await _db.database;
    final rows = await db.query('catches', orderBy: 'date DESC', limit: limit);
    return rows.map(CatchRecord.fromMap).toList();
  }

  static const Set<String> _allowedEquipmentColumns = {
    'rod_equipment_id',
    'reel_equipment_id',
    'line_equipment_id',
    'hook_equipment_id',
    'lure_equipment_id',
  };

  /// Недавно использованные ID снаряжения по заданной колонке
  /// (используется для подсказок при добавлении улова).
  Future<List<String>> getRecentEquipmentIds(String column, {int limit = 6}) async {
    if (!_allowedEquipmentColumns.contains(column)) {
      throw ArgumentError('Недопустимая колонка снаряжения: $column');
    }
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT $column as val, MAX(date) as last_used FROM catches
      WHERE $column IS NOT NULL GROUP BY $column ORDER BY last_used DESC LIMIT ?
    ''', [limit]);
    return rows.map((e) => e['val'] as String).toList();
  }
}
