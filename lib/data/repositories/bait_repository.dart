import '../database/app_database.dart';
import '../models/bait.dart';

class BaitRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Bait>> getAll({String? query}) async {
    final db = await _db.database;
    final where = query != null && query.trim().isNotEmpty ? 'name LIKE ?' : null;
    final args = where != null ? ['%${query!.trim()}%'] : null;
    final rows = await db.query('baits', where: where, whereArgs: args, orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Bait.fromMap).toList();
  }

  Future<Bait?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('baits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Bait.fromMap(rows.first);
  }

  Future<List<Bait>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query('baits', where: 'id IN ($placeholders)', whereArgs: ids);
    return rows.map(Bait.fromMap).toList();
  }

  Future<void> insert(Bait bait) async {
    final db = await _db.database;
    await db.insert('baits', bait.toMap());
  }

  Future<void> update(Bait bait) async {
    final db = await _db.database;
    await db.update('baits', bait.toMap(), where: 'id = ?', whereArgs: [bait.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('baits', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM baits');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<List<Bait>> getRecentlyUsed({int limit = 6}) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT b.* FROM baits b
      INNER JOIN (
        SELECT bait_id, MAX(date) as last_used FROM catches
        WHERE bait_id IS NOT NULL GROUP BY bait_id
      ) c ON c.bait_id = b.id
      ORDER BY c.last_used DESC LIMIT ?
    ''', [limit]);
    return rows.map(Bait.fromMap).toList();
  }
}
