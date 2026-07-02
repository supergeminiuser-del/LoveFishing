import '../database/app_database.dart';
import '../models/equipment_item.dart';

class EquipmentRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<EquipmentItem>> getAll({String? query, String? category}) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      conditions.add('name LIKE ?');
      args.add('%${query.trim()}%');
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }
    final rows = await db.query(
      'equipment',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(EquipmentItem.fromMap).toList();
  }

  Future<EquipmentItem?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query('equipment', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return EquipmentItem.fromMap(rows.first);
  }

  Future<List<EquipmentItem>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query('equipment', where: 'id IN ($placeholders)', whereArgs: ids);
    return rows.map(EquipmentItem.fromMap).toList();
  }

  Future<void> insert(EquipmentItem item) async {
    final db = await _db.database;
    await db.insert('equipment', item.toMap());
  }

  Future<void> update(EquipmentItem item) async {
    final db = await _db.database;
    await db.update('equipment', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM equipment');
    return (result.first['c'] as int?) ?? 0;
  }

  Future<Map<String, int>> countByCategory() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT category, COUNT(*) as c FROM equipment GROUP BY category');
    return {for (final r in rows) r['category'] as String: r['c'] as int};
  }
}
