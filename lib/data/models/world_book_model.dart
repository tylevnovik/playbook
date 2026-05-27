import '../../domain/entities/world_book.dart';

class WorldBookModel {
  static WorldBook fromMap(Map<String, dynamic> map) {
    return WorldBook(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(WorldBook worldBook) {
    return {
      'id': worldBook.id,
      'name': worldBook.name,
      'description': worldBook.description,
      'created_at': worldBook.createdAt.toIso8601String(),
      'updated_at': worldBook.updatedAt.toIso8601String(),
    };
  }
}

class WorldBookEntryModel {
  static WorldBookEntry fromMap(Map<String, dynamic> map) {
    return WorldBookEntry(
      id: map['id'] as String,
      worldBookId: map['world_book_id'] as String,
      name: map['name'] as String,
      keywords: (map['keywords'] as String).split(',').map((k) => k.trim()).toList(),
      content: map['content'] as String,
      category: map['category'] as String? ?? 'general',
      priority: map['priority'] as int? ?? 0,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toMap(WorldBookEntry entry) {
    return {
      'id': entry.id,
      'world_book_id': entry.worldBookId,
      'name': entry.name,
      'keywords': entry.keywords.join(','),
      'content': entry.content,
      'category': entry.category,
      'priority': entry.priority,
      'enabled': entry.enabled ? 1 : 0,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
    };
  }
}
