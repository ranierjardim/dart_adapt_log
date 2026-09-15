library adapt_log_sqlite_database_output_adapter;

import 'dart:convert';

import 'package:adapt_log/adapt_log.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqliteDatabaseOutputAdapter extends AdaptLogOutput {
  final String dbName;
  Database? _db;

  SqliteDatabaseOutputAdapter({this.dbName = 'adapt_log.db'});

  @override
  Future<void> initialize(AdaptLogController controller) async {
    final dbPath = join(await getDatabasesPath(), dbName);
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            level TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            stack_trace TEXT,
            metadata TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    await _db?.insert('logs', {
      'message': entry.message,
      'level': entry.level.name,
      'timestamp': entry.timestamp.toIso8601String(),
      'stack_trace': entry.stackTrace?.toString(),
      'metadata': jsonEncode(entry.metadata),
    });
  }

  Future<List<AdaptLogEntry>> getLogs({int? limit, AdaptLogLevel? level}) async {
    final where = level != null ? 'level = ?' : null;
    final whereArgs = level != null ? [level.name] : null;

    final rows = await _db?.query(
          'logs',
          where: where,
          whereArgs: whereArgs,
          orderBy: 'id DESC',
          limit: limit,
        ) ??
        [];

    return rows.map((row) {
      return AdaptLogEntry(
        message: row['message'] as String,
        level: AdaptLogLevel.values.byName(row['level'] as String),
        timestamp: DateTime.parse(row['timestamp'] as String),
        stackTrace: row['stack_trace'] != null
            ? StackTrace.fromString(row['stack_trace'] as String)
            : null,
        metadata: row['metadata'] != null
            ? Map<String, dynamic>.from(jsonDecode(row['metadata'] as String) as Map)
            : const {},
      );
    }).toList();
  }

  Future<void> clearLogs() async {
    await _db?.delete('logs');
  }

  @override
  Future<void> shutdown() async {
    await _db?.close();
  }
}
