import '../database/app_database.dart';
import '../models/fishing_trip.dart';

class TripRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<FishingTrip>> getAll({String? query}) async {
    final db = await _db.database;
    final where = query != null && query.trim().isNotEmpty
        ? '(title LIKE ? OR notes LIKE ?)'
        : null;
    final args = where != null ? ['%${query!.trim()}%', '%${query.trim()}%'] : null;
    final rows = await db.query('trips', where: where, whereArgs: args, orderBy: 'start_date DESC');
    return rows.map(FishingTrip.fromMap).toList();
  }

  Future<FishingTrip?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('trips', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return FishingTrip.fromMap(rows.first);
  }

  Future<void> insert(FishingTrip trip) async {
    final db = await _db.database;
    await db.insert('trips', trip.toMap());
  }

  Future<void> update(FishingTrip trip) async {
    final db = await _db.database;
    await db.update('trips', trip.toMap(), where: 'id = ?', whereArgs: [trip.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM trips');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> catchCountForTrip(String tripId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantity),0) AS c FROM catches WHERE trip_id = ?',
      [tripId],
    );
    return (result.first['c'] as int?) ?? 0;
  }
}
