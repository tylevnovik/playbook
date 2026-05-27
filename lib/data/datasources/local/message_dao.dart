import 'database_service.dart';

class MessageDao {
  Future<List<Map<String, dynamic>>> getByChatId(String chatId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await DatabaseService.database;
    final results = await db.query('messages', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getChildren(String parentId) async {
    final db = await DatabaseService.database;
    return await db.query(
      'messages',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getBranch(String chatId, String? leafId) async {
    final db = await DatabaseService.database;
    final messages = <Map<String, dynamic>>[];
    
    String? currentId = leafId;
    while (currentId != null) {
      final msg = await getById(currentId);
      if (msg == null) break;
      messages.insert(0, msg);
      currentId = msg['parent_id'] as String?;
    }
    
    // If no leaf specified, get the first/root branch
    if (leafId == null) {
      final roots = await db.query(
        'messages',
        where: 'chat_id = ? AND parent_id IS NULL',
        whereArgs: [chatId],
        orderBy: 'created_at ASC',
      );
      if (roots.isNotEmpty) {
        return await _buildBranch(chatId, roots.first['id'] as String);
      }
    }
    
    return messages;
  }

  Future<List<Map<String, dynamic>>> _buildBranch(String chatId, String rootId) async {
    final messages = <Map<String, dynamic>>[];
    String? currentId = rootId;
    
    while (currentId != null) {
      final msg = await getById(currentId);
      if (msg == null) break;
      messages.add(msg);
      
      final children = await getChildren(currentId);
      currentId = children.isNotEmpty ? children.first['id'] as String? : null;
    }
    
    return messages;
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.insert('messages', data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final db = await DatabaseService.database;
    await db.update('messages', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseService.database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}
