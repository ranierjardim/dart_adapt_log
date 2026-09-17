import 'dart:convert';
import 'dart:typed_data';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';
import 'package:sqlite3/sqlite3.dart';

import '../domain/log_query.dart';
import '../domain/log_record.dart';
import '../domain/log_repository.dart';
import '../domain/session_record.dart';
import '../domain/stored_screenshot.dart';

/// [LogRepository] em SQLite, via `package:sqlite3` (Dart puro, sem Flutter).
/// Use `:memory:` como caminho para um banco em memória.
class SqliteLogRepository implements LogRepository {
  final Database _db;

  SqliteLogRepository._(this._db);

  factory SqliteLogRepository.open(String path) {
    final db = sqlite3.open(path);
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA foreign_keys = ON');
    _migrate(db);
    return SqliteLogRepository._(db);
  }

  static void _migrate(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS logs (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        project TEXT NOT NULL,
        session_id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        received_at TEXT NOT NULL,
        error TEXT,
        error_type TEXT,
        stack_trace TEXT,
        metadata TEXT NOT NULL,
        UNIQUE (project, entry_id)
      )
    ''');
    db.execute('CREATE INDEX IF NOT EXISTS idx_logs_project_seq ON logs(project, seq)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_logs_project_level ON logs(project, level, seq)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_logs_project_session ON logs(project, session_id, seq)');
    db.execute('''
      CREATE TABLE IF NOT EXISTS screenshots (
        project TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        for_entry_id TEXT,
        format TEXT NOT NULL,
        width INTEGER,
        height INTEGER,
        data BLOB NOT NULL,
        PRIMARY KEY (project, entry_id)
      )
    ''');
    db.execute('CREATE INDEX IF NOT EXISTS idx_screenshots_for ON screenshots(project, for_entry_id)');
    db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        project TEXT NOT NULL,
        id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        last_seen_at TEXT NOT NULL,
        metadata TEXT NOT NULL,
        entry_count INTEGER NOT NULL DEFAULT 0,
        error_count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (project, id)
      )
    ''');
  }

  @override
  Future<List<LogRecord>> saveBatch({
    required String project,
    required SessionInfo session,
    required List<AdaptLogEntry> entries,
    required DateTime receivedAt,
  }) async {
    final stored = <LogRecord>[];
    _db.execute('BEGIN IMMEDIATE');
    try {
      _db.execute(
        '''
        INSERT INTO sessions (project, id, started_at, last_seen_at, metadata, entry_count, error_count)
        VALUES (?, ?, ?, ?, ?, 0, 0)
        ON CONFLICT (project, id) DO UPDATE SET
          last_seen_at = excluded.last_seen_at,
          metadata = CASE WHEN length(excluded.metadata) > 2 THEN excluded.metadata ELSE sessions.metadata END
        ''',
        [
          project,
          session.id,
          session.startedAt.toUtc().toIso8601String(),
          receivedAt.toUtc().toIso8601String(),
          jsonEncode(AdaptLogEntry.jsonSafe(session.metadata)),
        ],
      );
      final insert = _db.prepare('''
        INSERT OR IGNORE INTO logs
          (project, session_id, entry_id, level, message, timestamp, received_at, error, error_type, stack_trace, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');
      final insertScreenshot = _db.prepare('''
        INSERT OR REPLACE INTO screenshots (project, entry_id, for_entry_id, format, width, height, data)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''');
      try {
        var errors = 0;
        for (final original in entries) {
          final screenshot = _extractScreenshot(original);
          final entry = screenshot == null ? original : screenshot.entry;
          insert.execute([
            project,
            session.id,
            entry.id,
            entry.level.name,
            entry.message,
            entry.timestamp.toUtc().toIso8601String(),
            receivedAt.toUtc().toIso8601String(),
            entry.error?.toString(),
            entry.errorType,
            entry.stackTrace?.toString(),
            jsonEncode(AdaptLogEntry.jsonSafe(entry.metadata)),
          ]);
          if (_db.updatedRows == 0) continue;
          if (entry.level == AdaptLogLevel.error) errors++;
          if (screenshot != null) {
            insertScreenshot.execute([
              project,
              entry.id,
              screenshot.forEntryId,
              screenshot.format,
              screenshot.width,
              screenshot.height,
              screenshot.bytes,
            ]);
            final forEntryId = screenshot.forEntryId;
            if (forEntryId != null) _markHasScreenshot(project, forEntryId);
          }
          stored.add(LogRecord(
            seq: _db.lastInsertRowId,
            project: project,
            sessionId: session.id,
            receivedAt: receivedAt.toUtc(),
            entry: entry,
          ));
        }
        _db.execute(
          'UPDATE sessions SET entry_count = entry_count + ?, error_count = error_count + ? WHERE project = ? AND id = ?',
          [stored.length, errors, project, session.id],
        );
      } finally {
        insert.dispose();
        insertScreenshot.dispose();
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return stored;
  }

  @override
  Future<List<LogRecord>> query(LogQuery query) async {
    final where = <String>['project = ?'];
    final args = <Object?>[query.project];
    if (query.level != null) {
      where.add('level = ?');
      args.add(query.level!.name);
    }
    if (query.sessionId != null) {
      where.add('session_id = ?');
      args.add(query.sessionId);
    }
    final search = query.search;
    if (search != null && search.isNotEmpty) {
      where.add("message LIKE ? ESCAPE '\\'");
      args.add('%${search.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%');
    }
    if (query.beforeSeq != null) {
      where.add('seq < ?');
      args.add(query.beforeSeq);
    }
    args.add(query.limit);
    final rows = _db.select(
      'SELECT * FROM logs WHERE ${where.join(' AND ')} ORDER BY seq DESC LIMIT ?',
      args,
    );
    return rows.map(_toRecord).toList();
  }

  @override
  Future<LogRecord?> findByEntryId(String project, String entryId) async {
    final rows = _db.select(
      'SELECT * FROM logs WHERE project = ? AND entry_id = ? LIMIT 1',
      [project, entryId],
    );
    return rows.isEmpty ? null : _toRecord(rows.first);
  }

  @override
  Future<List<SessionRecord>> sessions(String project, {int limit = 100}) async {
    final rows = _db.select(
      'SELECT * FROM sessions WHERE project = ? ORDER BY last_seen_at DESC LIMIT ?',
      [project, limit.clamp(1, 1000)],
    );
    return [
      for (final row in rows)
        SessionRecord(
          id: row['id'] as String,
          project: row['project'] as String,
          startedAt: DateTime.parse(row['started_at'] as String),
          lastSeenAt: DateTime.parse(row['last_seen_at'] as String),
          metadata: Map<String, dynamic>.from(jsonDecode(row['metadata'] as String) as Map),
          entryCount: row['entry_count'] as int,
          errorCount: row['error_count'] as int,
        ),
    ];
  }

  @override
  Future<StoredScreenshot?> findScreenshot(String project, String entryId) async {
    final rows = _db.select(
      'SELECT format, width, height, data FROM screenshots '
      'WHERE project = ? AND (entry_id = ? OR for_entry_id = ?) ORDER BY rowid DESC LIMIT 1',
      [project, entryId, entryId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return StoredScreenshot(
      format: row['format'] as String,
      width: row['width'] as int?,
      height: row['height'] as int?,
      bytes: row['data'] as Uint8List,
    );
  }

  @override
  Future<void> close() async => _db.dispose();

  /// Separa a imagem de uma entry de screenshot: devolve a entry sem o
  /// base64 na metadata (marcada com `hasScreenshot`) e os bytes.
  _ExtractedScreenshot? _extractScreenshot(AdaptLogEntry entry) {
    final metadata = entry.metadata;
    if (metadata['isScreenshot'] != true) return null;
    final encoded = metadata['screenshot'];
    if (encoded is! String) return null;
    Uint8List bytes;
    try {
      bytes = base64Decode(encoded);
    } on FormatException {
      return null;
    }
    final stripped = Map<String, dynamic>.from(metadata)
      ..remove('screenshot')
      ..['hasScreenshot'] = true;
    return _ExtractedScreenshot(
      entry: entry.copyWith(metadata: stripped),
      forEntryId: metadata['screenshotFor']?.toString(),
      format: metadata['screenshotFormat']?.toString() ?? 'png',
      width: metadata['screenshotWidth'] is int ? metadata['screenshotWidth'] as int : null,
      height: metadata['screenshotHeight'] is int ? metadata['screenshotHeight'] as int : null,
      bytes: bytes,
    );
  }

  void _markHasScreenshot(String project, String entryId) {
    final rows = _db.select(
      'SELECT metadata FROM logs WHERE project = ? AND entry_id = ?',
      [project, entryId],
    );
    if (rows.isEmpty) return;
    final metadata = Map<String, dynamic>.from(jsonDecode(rows.first['metadata'] as String) as Map);
    if (metadata['hasScreenshot'] == true) return;
    metadata['hasScreenshot'] = true;
    _db.execute(
      'UPDATE logs SET metadata = ? WHERE project = ? AND entry_id = ?',
      [jsonEncode(metadata), project, entryId],
    );
  }

  LogRecord _toRecord(Row row) {
    return LogRecord(
      seq: row['seq'] as int,
      project: row['project'] as String,
      sessionId: row['session_id'] as String,
      receivedAt: DateTime.parse(row['received_at'] as String),
      entry: AdaptLogEntry.fromJson({
        'id': row['entry_id'],
        'message': row['message'],
        'level': row['level'],
        'timestamp': row['timestamp'],
        'error': row['error'],
        'errorType': row['error_type'],
        'stackTrace': row['stack_trace'],
        'metadata': jsonDecode(row['metadata'] as String),
      }),
    );
  }
}

class _ExtractedScreenshot {
  final AdaptLogEntry entry;
  final String? forEntryId;
  final String format;
  final int? width;
  final int? height;
  final Uint8List bytes;

  const _ExtractedScreenshot({
    required this.entry,
    required this.forEntryId,
    required this.format,
    required this.width,
    required this.height,
    required this.bytes,
  });
}
