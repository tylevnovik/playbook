import 'database_service.dart';

class CharacterDao {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseService.database;
    return await db.query('characters', orderBy: 'last_chatted_at DESC');
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('characters', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('characters', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('characters', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final db = await DatabaseService.database;
    return await db.query(
      'characters',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }
}
