import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/event_model.dart';
import '../models/category_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quiz_calendar.db');
    // v5 scopes local queries and offline queue by user_id.
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<bool> _hasColumn(Database db, String table, String column) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    return columns.any((row) => row['name'] == column);
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    if (!await _hasColumn(db, table, column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  // method for db update if user already installed app
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE events ADD COLUMN is_completed INTEGER DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      await _ensureColumn(db, 'events', 'start_at', 'TEXT');
      await _ensureColumn(db, 'events', 'end_at', 'TEXT');
      await _ensureColumn(db, 'events', 'priority', 'INTEGER DEFAULT 2');
      await _ensureColumn(db, 'events', 'remind_before', 'INTEGER');

      if (await _hasColumn(db, 'events', 'start_time')) {
        await db.execute(
          'UPDATE events SET start_at = start_time WHERE start_at IS NULL AND start_time IS NOT NULL',
        );
      }

      if (await _hasColumn(db, 'events', 'end_time')) {
        await db.execute(
          'UPDATE events SET end_at = end_time WHERE end_at IS NULL AND end_time IS NOT NULL',
        );
      }

      if (await _hasColumn(db, 'events', 'reminder_minutes')) {
        await db.execute(
          'UPDATE events SET remind_before = reminder_minutes WHERE remind_before IS NULL AND reminder_minutes IS NOT NULL',
        );
      }
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_category_ops (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          op_type TEXT NOT NULL,
          category_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          payload TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      // Drop legacy queue rows that were not user-scoped.
      await db.execute('DROP TABLE IF EXISTS pending_category_ops');
      await db.execute('''
        CREATE TABLE pending_category_ops (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          op_type TEXT NOT NULL,
          category_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          payload TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT,
        icon TEXT,
        user_id TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        is_completed INTEGER DEFAULT 0,
        start_at TEXT,
        end_at TEXT,
        category_id TEXT,
        user_id TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 2,
        remind_before INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_category_ops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        op_type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        payload TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> updateEventFields(
    String id,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    final db = await database;

    // copy map to not kill og table
    final Map<String, dynamic> dbUpdates = Map.from(updates);

    if (dbUpdates.containsKey('isCompleted')) {
      dbUpdates['is_completed'] = dbUpdates.remove('isCompleted');
    }
    if (dbUpdates.containsKey('categoryId')) {
      dbUpdates['category_id'] = dbUpdates.remove('categoryId');
    }
    if (dbUpdates.containsKey('startTime')) {
      dbUpdates['start_at'] = dbUpdates.remove('startTime');
    }
    if (dbUpdates.containsKey('endTime')) {
      dbUpdates['end_at'] = dbUpdates.remove('endTime');
    }
    if (dbUpdates.containsKey('reminderMinutes')) {
      dbUpdates['remind_before'] = dbUpdates.remove('reminderMinutes');
    }

    // convert bool into int for sqlite
    if (dbUpdates.containsKey('is_completed')) {
      dbUpdates['is_completed'] = dbUpdates['is_completed'] == true ? 1 : 0;
    }
    if (dbUpdates.containsKey('is_deleted')) {
      dbUpdates['is_deleted'] = dbUpdates['is_deleted'] == true ? 1 : 0;
    }
    if (dbUpdates.containsKey('priority')) {
      final raw = dbUpdates['priority'];
      if (raw is String) {
        if (raw == 'low') dbUpdates['priority'] = 1;
        if (raw == 'high') dbUpdates['priority'] = 3;
        if (raw == 'medium') dbUpdates['priority'] = 2;
      }
    }

    dbUpdates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await db.update(
      'events',
      dbUpdates,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> upsertEvent(EventModel event) async {
    final db = await database;
    await db.insert(
      'events',
      event.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertEventsBatch(List<EventModel> events) async {
    if (events.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final event in events) {
      batch.insert(
        'events',
        event.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<EventModel>> getActiveEvents(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'is_deleted = 0 AND user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => EventModel.fromJson(maps[i]));
  }

  Future<List<EventModel>> getAllEventsForSync(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => EventModel.fromJson(maps[i]));
  }

  Future<void> softDeleteEvent(String id, String userId) async {
    await updateEventFields(id, {'is_deleted': true}, userId);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('events');
    await db.delete('categories');
    await db.delete('pending_category_ops');
  }

  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('events', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('categories', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete(
      'pending_category_ops',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> upsertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert(
      'categories',
      category.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertCategoriesBatch(List<CategoryModel> categories) async {
    if (categories.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final category in categories) {
      batch.insert(
        'categories',
        category.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CategoryModel>> getActiveCategories(String userId) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'is_deleted = 0 AND user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => CategoryModel.fromJson(maps[i]));
  }

  Future<void> deleteCategoryLocal(String id, String userId) async {
    final db = await database;
    await db.update(
      'events',
      {
        'category_id': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'category_id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    await db.delete(
      'categories',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> enqueueCategoryOperation({
    required String opType,
    required String categoryId,
    required String userId,
    Map<String, dynamic>? payload,
  }) async {
    final db = await database;
    await db.insert('pending_category_ops', {
      'op_type': opType,
      'category_id': categoryId,
      'user_id': userId,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingCategoryOperations(
    String userId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'pending_category_ops',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
    return rows.map((row) {
      final payloadRaw = row['payload'];
      Map<String, dynamic>? decodedPayload;
      if (payloadRaw is String && payloadRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(payloadRaw);
          if (decoded is Map<String, dynamic>) {
            decodedPayload = decoded;
          }
        } catch (_) {
          decodedPayload = null;
        }
      }
      return {
        'id': row['id'],
        'op_type': row['op_type'],
        'category_id': row['category_id'],
        'payload': decodedPayload,
      };
    }).toList();
  }

  Future<void> removePendingCategoryOperation(int operationId) async {
    final db = await database;
    await db.delete(
      'pending_category_ops',
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }
}
