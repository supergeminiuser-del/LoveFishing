import '../database/app_database.dart';
import '../models/map_area.dart';

class MapAreaRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<MapArea>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('map_areas', orderBy: 'created_at DESC');
    return rows.map(MapArea.fromMap).toList();
  }

  Future<void> insert(MapArea area) async {
    final db = await _db.database;
    await db.insert('map_areas', area.toMap());
  }

  Future<void> update(MapArea area) async {
    final db = await _db.database;
    await db.update('map_areas', area.toMap(), where: 'id = ?', whereArgs: [area.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('map_areas', where: 'id = ?', whereArgs: [id]);
  }
}
