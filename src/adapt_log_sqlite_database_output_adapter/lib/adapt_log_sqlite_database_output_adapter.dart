library adapt_log_sqlite_database_output_adapter;

import 'dart:convert';

import 'package:adapt_log/adapt_log.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Persiste as entries em um banco SQLite local.
///
/// - [maxEntries] limita o tamanho da tabela: as entries mais antigas são
///   removidas quando o limite é ultrapassado. A poda roda a cada
///   [pruneInterval] inserções e em [initialize]. `null` desativa a poda.
/// - `metadata` é gravada como JSON; valores não serializáveis viram
///   `toString()`. `timestamp` é gravado em UTC.
class SqliteDatabaseOutputAdapter extends AdaptLogOutput {
  static const _table = 'logs';

  /// Nome do arquivo dentro de `getDatabasesPath()`.
  final String dbName;

  /// Caminho completo do arquivo. Se informado, [dbName] é ignorado.
  final String? path;

  final int? maxEntries;
  final int pruneInterval;

  Database? _db;
  int _insertsSincePrune = 0;

  SqliteDatabaseOutputAdapter({
    this.dbName = 'adapt_log.db',
    this.path,
    this.maxEntries = 10000,
    this.pruneInterval = 100,
  }) : assert(pruneInterval > 0);

  /// Banco aberto em [initialize]; `null` antes disso e depois de [shutdown].
  Database? get database => _db;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    final dbPath = path ?? p.join(await getDatabasesPath(), dbName);
    final db = _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_id TEXT NOT NULL UNIQUE,
            message TEXT NOT NULL,
            level TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            error TEXT,
            error_type TEXT,
            stack_trace TEXT,
            metadata TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_${_table}_level ON $_table(level)');
        await db.execute('CREATE INDEX idx_${_table}_timestamp ON $_table(timestamp)');
      },
    );
    await _prune(db);
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    final db = _db;
    if (db == null) return;
    await db.insert(
      _table,
      {
        'entry_id': entry.id,
        'message': entry.message,
        'level': entry.level.name,
        'timestamp': entry.timestamp.toUtc().toIso8601String(),
        'error': entry.error?.toString(),
        'error_type': entry.errorType,
        'stack_trace': entry.stackTrace?.toString(),
        'metadata': jsonEncode(AdaptLogEntry.jsonSafe(entry.metadata)),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (++_insertsSincePrune >= pruneInterval) {
      _insertsSincePrune = 0;
      await _prune(db);
    }
  }

  /// Entries armazenadas, das mais recentes para as mais antigas.
  Future<List<AdaptLogEntry>> getLogs({int? limit, AdaptLogLevel? level}) async {
    final db = _db;
    if (db == null) return const [];
    final rows = await db.query(
      _table,
      where: level != null ? 'level = ?' : null,
      whereArgs: level != null ? [level.name] : null,
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> count() async {
    final db = _db;
    if (db == null) return 0;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_table')) ?? 0;
  }

  Future<void> clearLogs() async {
    await _db?.delete(_table);
  }

  @override
  Future<void> shutdown() async {
    final db = _db;
    _db = null;
    await db?.close();
    await super.shutdown();
  }

  Future<void> _prune(Database db) async {
    final max = maxEntries;
    if (max == null) return;
    await db.execute(
      'DELETE FROM $_table WHERE id <= '
      '(SELECT id FROM $_table ORDER BY id DESC LIMIT 1 OFFSET ?)',
      [max],
    );
  }

  AdaptLogEntry _fromRow(Map<String, Object?> row) {
    final error = row['error'] as String?;
    final stackTrace = row['stack_trace'] as String?;
    final metadata = row['metadata'] as String?;
    return AdaptLogEntry(
      id: row['entry_id'] as String,
      message: row['message'] as String,
      level: AdaptLogLevel.values.byName(row['level'] as String),
      timestamp: DateTime.parse(row['timestamp'] as String),
      error: error == null
          ? null
          : AdaptLogSerializedError(type: row['error_type'] as String? ?? 'Object', message: error),
      stackTrace: stackTrace != null ? StackTrace.fromString(stackTrace) : null,
      metadata: metadata != null
          ? Map<String, dynamic>.from(jsonDecode(metadata) as Map)
          : const {},
    );
  }
}
