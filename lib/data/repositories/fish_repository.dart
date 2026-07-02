import '../database/app_database.dart';
import '../models/fish.dart';

class FishRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Fish>> getAll({String? query}) async {
    final db = await _db.database;
    final where = query != null && query.trim().isNotEmpty ? 'name LIKE ?' : null;
    final args = where != null ? ['%${query!.trim()}%'] : null;
    final rows = await db.query('fish', where: where, whereArgs: args, orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Fish.fromMap).toList();
  }

  Future<Fish?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('fish', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Fish.fromMap(rows.first);
  }

  Future<List<Fish>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query('fish', where: 'id IN ($placeholders)', whereArgs: ids);
    return rows.map(Fish.fromMap).toList();
  }

  Future<void> insert(Fish fish) async {
    final db = await _db.database;
    await db.insert('fish', fish.toMap());
  }

  Future<void> update(Fish fish) async {
    final db = await _db.database;
    await db.update('fish', fish.toMap(), where: 'id = ?', whereArgs: [fish.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('fish', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM fish');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<List<Fish>> getRecentlyUsed({int limit = 6}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT f.* FROM fish f
      INNER JOIN (
        SELECT fish_id, MAX(date) as last_used FROM catches
        WHERE fish_id IS NOT NULL GROUP BY fish_id
      ) c ON c.fish_id = f.id
      ORDER BY c.last_used DESC LIMIT ?
    ''', [limit]);
    return rows.map(Fish.fromMap).toList();
  }
}
