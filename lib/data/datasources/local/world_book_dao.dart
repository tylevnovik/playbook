import 'database_service.dart';

class WorldBookDao {
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await DatabaseService.database;
    return await db.query('world_books', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'world_books',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('world_books', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('world_books', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('world_books', where: 'id = ?', whereArgs: [id]);
  }

  // Entries
  Future<List<Map<String, dynamic>>> getEntries(String worldBookId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'world_book_entries',
      where: 'world_book_id = ?',
      whereArgs: [worldBookId],
      orderBy: 'priority DESC',
    );
  }

  Future<void> insertEntry(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('world_book_entries', data);
  }

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update(
      'world_book_entries',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEntry(String id) async {
    final db = await DatabaseService.database;
    await db.delete('world_book_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> matchEntries(
    String worldBookId,
    String text,
  ) async {
    final db = await DatabaseService.database;
    final entries = await db.query(
      'world_book_entries',
      where: 'world_book_id = ? AND enabled = 1',
      whereArgs: [worldBookId],
    );

    return entries.where((entry) {
      final keywords = (entry['keywords'] as String).split(',');
      return keywords.any(
        (k) => text.toLowerCase().contains(k.trim().toLowerCase()),
      );
    }).toList();
  }
}
