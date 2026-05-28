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
        final canonRoot = roots.firstWhere(
          (r) => r['is_canon'] == 1,
          orElse: () => roots.first,
        );
        return await _buildBranch(chatId, canonRoot['id'] as String);
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
      if (children.isEmpty) {
        currentId = null;
      } else {
        final canonChild = children.firstWhere(
          (c) => c['is_canon'] == 1,
          orElse: () => children.first,
        );
        currentId = canonChild['id'] as String;
      }
    }
    
    return messages;
  }

  Future<void> setMessageCanon(String id, bool isCanon) async {
    final db = await DatabaseService.database;
    final msg = await getById(id);
    if (msg == null) return;
    
    final parentId = msg['parent_id'] as String?;
    final chatId = msg['chat_id'] as String;
    
    if (isCanon) {
      // Clear canon flag for all siblings (sharing same parentId and chatId)
      if (parentId != null) {
        await db.update(
          'messages',
          {'is_canon': 0},
          where: 'chat_id = ? AND parent_id = ?',
          whereArgs: [chatId, parentId],
        );
      } else {
        await db.update(
          'messages',
          {'is_canon': 0},
          where: 'chat_id = ? AND parent_id IS NULL',
          whereArgs: [chatId],
        );
      }
      
      // Set canon flag for the target message
      await db.update(
        'messages',
        {'is_canon': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.update(
        'messages',
        {'is_canon': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
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
