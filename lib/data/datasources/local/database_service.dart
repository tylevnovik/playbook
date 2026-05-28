import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    final db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Online repair: If the database is already on version 2, but has 'character_id' leftover in 'chats' table
    final chatsTableInfo = await db.rawQuery('PRAGMA table_info(chats)');
    final hasChatsCharacterId = chatsTableInfo.any((column) => column['name'] == 'character_id');
    if (hasChatsCharacterId) {
      await db.transaction((txn) async {
        final existingChats = await txn.query('chats', columns: ['id', 'character_id']);
        
        await txn.execute('ALTER TABLE chats RENAME TO chats_old');
        await txn.execute('''
          CREATE TABLE chats (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await txn.execute('INSERT INTO chats (id, created_at, updated_at) SELECT id, created_at, updated_at FROM chats_old');
        await txn.execute('DROP TABLE chats_old');

        // Migrate relations to chat_characters just in case
        for (final chat in existingChats) {
          final chatId = chat['id'] as String;
          final charId = chat['character_id'] as String?;
          if (charId != null && charId.isNotEmpty) {
            final exists = await txn.query(
              'chat_characters',
              where: 'chat_id = ? AND character_id = ?',
              whereArgs: [chatId, charId],
            );
            if (exists.isEmpty) {
              await txn.insert('chat_characters', {
                'chat_id': chatId,
                'character_id': charId,
              });
            }
          }
        }
      });
    }

    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE characters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar_path TEXT,
        description TEXT NOT NULL,
        greeting TEXT NOT NULL,
        example_messages TEXT,
        system_prompt TEXT,
        tags TEXT DEFAULT '[]',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_chatted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        summary TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        parent_id TEXT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        attachments TEXT,
        tokens_used INTEGER,
        created_at TEXT NOT NULL,
        is_canon INTEGER DEFAULT 0,
        sender_id TEXT,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES messages(id),
        FOREIGN KEY (sender_id) REFERENCES characters(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE world_books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE world_book_entries (
        id TEXT PRIMARY KEY,
        world_book_id TEXT NOT NULL,
        name TEXT NOT NULL,
        keywords TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT DEFAULT 'general',
        priority INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (world_book_id) REFERENCES world_books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_characters (
        chat_id TEXT NOT NULL,
        character_id TEXT NOT NULL,
        PRIMARY KEY (chat_id, character_id),
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
        FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_world_books (
        chat_id TEXT NOT NULL,
        world_book_id TEXT NOT NULL,
        PRIMARY KEY (chat_id, world_book_id),
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
        FOREIGN KEY (world_book_id) REFERENCES world_books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE character_world_books (
        character_id TEXT NOT NULL,
        world_book_id TEXT NOT NULL,
        PRIMARY KEY (character_id, world_book_id),
        FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
        FOREIGN KEY (world_book_id) REFERENCES world_books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE story_states (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        category TEXT NOT NULL,
        target_id TEXT,
        content TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_messages_chat ON messages(chat_id)');
    await db.execute('CREATE INDEX idx_messages_parent ON messages(parent_id)');
    await db.execute(
      'CREATE INDEX idx_entries_worldbook ON world_book_entries(world_book_id)',
    );
    await db.execute('CREATE INDEX idx_chat_characters_chat ON chat_characters(chat_id)');
    await db.execute('CREATE INDEX idx_chat_characters_character ON chat_characters(character_id)');
    await db.execute('CREATE INDEX idx_chat_world_books_chat ON chat_world_books(chat_id)');
    await db.execute('CREATE INDEX idx_character_world_books_char ON character_world_books(character_id)');
    await db.execute('CREATE INDEX idx_story_states_chat ON story_states(chat_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Check schemas
      final chatsTableInfo = await db.rawQuery('PRAGMA table_info(chats)');
      final hasChatsCharacterId = chatsTableInfo.any((column) => column['name'] == 'character_id');

      final charsTableInfo = await db.rawQuery('PRAGMA table_info(characters)');
      final hasCharsWorldBookId = charsTableInfo.any((column) => column['name'] == 'world_book_id');

      // 2. Read and cache migration data
      List<Map<String, dynamic>> cachedChats = [];
      if (hasChatsCharacterId) {
        cachedChats = await db.query('chats', columns: ['id', 'character_id']);
      }

      List<Map<String, dynamic>> cachedChars = [];
      if (hasCharsWorldBookId) {
        cachedChars = await db.query('characters', columns: ['id', 'world_book_id']);
      }

      // 3. Rebuild chats table to drop 'character_id' (NOT NULL constraint)
      if (hasChatsCharacterId) {
        await db.execute('ALTER TABLE chats RENAME TO chats_old');
        await db.execute('''
          CREATE TABLE chats (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('INSERT INTO chats (id, created_at, updated_at) SELECT id, created_at, updated_at FROM chats_old');
        await db.execute('DROP TABLE chats_old');
      }

      // 4. Create join tables and indexes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_characters (
          chat_id TEXT NOT NULL,
          character_id TEXT NOT NULL,
          PRIMARY KEY (chat_id, character_id),
          FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
          FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_world_books (
          chat_id TEXT NOT NULL,
          world_book_id TEXT NOT NULL,
          PRIMARY KEY (chat_id, world_book_id),
          FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
          FOREIGN KEY (world_book_id) REFERENCES world_books(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS character_world_books (
          character_id TEXT NOT NULL,
          world_book_id TEXT NOT NULL,
          PRIMARY KEY (character_id, world_book_id),
          FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
          FOREIGN KEY (world_book_id) REFERENCES world_books(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_characters_chat ON chat_characters(chat_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_characters_character ON chat_characters(character_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_world_books_chat ON chat_world_books(chat_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_character_world_books_char ON character_world_books(character_id)');

      // 5. Add sender_id to messages
      final tableInfo = await db.rawQuery('PRAGMA table_info(messages)');
      final hasSenderId = tableInfo.any((column) => column['name'] == 'sender_id');
      if (!hasSenderId) {
        await db.execute('ALTER TABLE messages ADD COLUMN sender_id TEXT');
      }

      // 6. Insert cached relations into join tables
      for (final chat in cachedChats) {
        final chatId = chat['id'] as String;
        final charId = chat['character_id'] as String?;
        if (charId != null && charId.isNotEmpty) {
          final exists = await db.query(
            'chat_characters',
            where: 'chat_id = ? AND character_id = ?',
            whereArgs: [chatId, charId],
          );
          if (exists.isEmpty) {
            await db.insert('chat_characters', {
              'chat_id': chatId,
              'character_id': charId,
            });
          }
        }
      }

      for (final char in cachedChars) {
        final charId = char['id'] as String;
        final wbId = char['world_book_id'] as String?;
        if (wbId != null && wbId.isNotEmpty) {
          final exists = await db.query(
            'character_world_books',
            where: 'character_id = ? AND world_book_id = ?',
            whereArgs: [charId, wbId],
          );
          if (exists.isEmpty) {
            await db.insert('character_world_books', {
              'character_id': charId,
              'world_book_id': wbId,
            });
          }
        }
      }

      // 7. Fill message sender_id for old assistant messages
      if (hasChatsCharacterId) {
        await db.execute('''
          UPDATE messages
          SET sender_id = (SELECT character_id FROM chat_characters WHERE chat_characters.chat_id = messages.chat_id LIMIT 1)
          WHERE role = 'assistant' AND sender_id IS NULL
        ''');
      }
    }

    if (oldVersion < 3) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(chats)');
      final hasSummary = tableInfo.any((column) => column['name'] == 'summary');
      if (!hasSummary) {
        await db.execute('ALTER TABLE chats ADD COLUMN summary TEXT');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS story_states (
          id TEXT PRIMARY KEY,
          chat_id TEXT NOT NULL,
          category TEXT NOT NULL,
          target_id TEXT,
          content TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_story_states_chat ON story_states(chat_id)');
    }

    if (oldVersion < 4) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(messages)');
      final hasIsCanon = tableInfo.any((column) => column['name'] == 'is_canon');
      if (!hasIsCanon) {
        await db.execute('ALTER TABLE messages ADD COLUMN is_canon INTEGER DEFAULT 0');
      }
    }
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
