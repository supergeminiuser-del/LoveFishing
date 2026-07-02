import '../database/app_database.dart';
import '../models/gps_route.dart';

class RouteRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<GpsRoute>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('routes', orderBy: 'started_at DESC');
    return rows.map(GpsRoute.fromMap).toList();
  }

  Future<List<GpsRoute>> getForTrip(String tripId) async {
    final db = await _db.database;
    final rows = await db.query('routes', where: 'trip_id = ?', whereArgs: [tripId], orderBy: 'started_at DESC');
    return rows.map(GpsRoute.fromMap).toList();
  }

  Future<void> insert(GpsRoute route) async {
    final db = await _db.database;
    await db.insert('routes', route.toMap());
  }

  Future<void> update(GpsRoute route) async {
    final db = await _db.database;
    await db.update('routes', route.toMap(), where: 'id = ?', whereArgs: [route.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('routes', where: 'id = ?', whereArgs: [id]);
  }
}
