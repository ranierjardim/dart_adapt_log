import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_sqlite_database_output_adapter/adapt_log_sqlite_database_output_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Emitter extends AdaptLogInput {
  Future<void> emit(
    String message, {
    AdaptLogLevel level = AdaptLogLevel.info,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    return controller.log(AdaptLogEntry(
      message: message,
      level: level,
      stackTrace: stackTrace,
      metadata: metadata,
    ));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Emitter emitter;
  late SqliteDatabaseOutputAdapter db;
  late List<Object> errors;
  late AdaptLog adaptLog;

  Future<void> start({int? maxEntries = 10000, int pruneInterval = 100}) async {
    emitter = Emitter();
    db = SqliteDatabaseOutputAdapter(
      path: inMemoryDatabasePath,
      maxEntries: maxEntries,
      pruneInterval: pruneInterval,
    );
    errors = [];
    adaptLog = AdaptLog(
      inputs: [emitter],
      outputs: [db],
      onError: (error, _, __) => errors.add(error),
    );
    await adaptLog.initialize();
  }

  tearDown(() => adaptLog.shutdown());

  test('grava e lê entries com todos os campos', () async {
    await start();
    final stack = StackTrace.current;
    final when = DateTime.utc(2026, 9, 15, 12, 0);

    final original = AdaptLogEntry(
      message: 'falhou',
      level: AdaptLogLevel.error,
      timestamp: when,
      error: StateError('estado ruim'),
      stackTrace: stack,
      metadata: {'userId': 42, 'tags': ['a', 'b']},
    );
    await adaptLog.controller.log(original);

    final entry = (await db.getLogs()).single;
    expect(errors, isEmpty);
    expect(entry.id, original.id);
    expect(entry.error.toString(), 'Bad state: estado ruim');
    expect(entry.errorType, 'StateError');
    expect(entry.message, 'falhou');
    expect(entry.level, AdaptLogLevel.error);
    expect(entry.timestamp, when);
    expect(entry.stackTrace.toString(), stack.toString());
    expect(entry.metadata, {'userId': 42, 'tags': ['a', 'b']});
  });

  test('getLogs devolve das mais recentes para as mais antigas, com filtro e limite', () async {
    await start();
    await emitter.emit('1');
    await emitter.emit('2', level: AdaptLogLevel.error);
    await emitter.emit('3');
    await emitter.emit('4', level: AdaptLogLevel.error);

    expect((await db.getLogs()).map((e) => e.message), ['4', '3', '2', '1']);
    expect((await db.getLogs(level: AdaptLogLevel.error)).map((e) => e.message), ['4', '2']);
    expect((await db.getLogs(limit: 2)).map((e) => e.message), ['4', '3']);
    expect(await db.count(), 4);
  });

  test('metadata com valor não serializável não derruba a gravação', () async {
    await start();
    final when = DateTime.utc(2026, 1, 1);

    await emitter.emit('x', metadata: {'when': when});

    expect(errors, isEmpty);
    expect((await db.getLogs()).single.metadata['when'], when.toString());
  });

  test('poda mantém no máximo maxEntries, as mais recentes', () async {
    await start(maxEntries: 5, pruneInterval: 1);
    for (var i = 1; i <= 20; i++) {
      await emitter.emit('$i');
    }

    expect(await db.count(), 5);
    expect((await db.getLogs()).map((e) => e.message), ['20', '19', '18', '17', '16']);
  });

  test('clearLogs esvazia a tabela', () async {
    await start();
    await emitter.emit('a');
    await db.clearLogs();

    expect(await db.count(), 0);
  });
}
