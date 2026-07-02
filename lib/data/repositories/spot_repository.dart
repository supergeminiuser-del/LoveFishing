import '../database/app_database.dart';
import '../models/fishing_spot.dart';

class SpotRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<FishingSpot>> getAll({String? query, bool onlyFavorites = false}) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      conditions.add('name LIKE ?');
      args.add('%${query.trim()}%');
    }
    if (onlyFavorites) {
      conditions.add('is_favorite = 1');
    }
    final rows = await db.query(
      'spots',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'is_favorite DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(FishingSpot.fromMap).toList();
  }

  Future<FishingSpot?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('spots', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return FishingSpot.fromMap(rows.first);
  }

  Future<void> insert(FishingSpot spot) async {
    final db = await _db.database;
    await db.insert('spots', spot.toMap());
  }

  Future<void> update(FishingSpot spot) async {
    final db = await _db.database;
    await db.update('spots', spot.toMap(), where: 'id = ?', whereArgs: [spot.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('spots', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM spots');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<List<FishingSpot>> getRecentlyUsed({int limit = 6}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT s.* FROM spots s
      INNER JOIN (
        SELECT spot_id, MAX(date) as last_used FROM catches
        WHERE spot_id IS NOT NULL GROUP BY spot_id
      ) c ON c.spot_id = s.id
      ORDER BY c.last_used DESC LIMIT ?
    ''', [limit]);
    return rows.map(FishingSpot.fromMap).toList();
  }

  /// Самое посещаемое (любимое по частоте уловов) место.
  Future<Map<String, Object?>?> getMostProductiveSpot() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT s.*, COUNT(c.id) as catch_count FROM spots s
      INNER JOIN catches c ON c.spot_id = s.id
      GROUP BY s.id ORDER BY catch_count DESC LIMIT 1
    ''');
    if (rows.isEmpty) return null;
    return rows.first;
  }
}
