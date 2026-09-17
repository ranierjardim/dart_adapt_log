import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_sqlite_database_output_adapter/adapt_log_sqlite_database_output_adapter.dart';
import 'package:flutter/material.dart';

class _Emitter extends AdaptLogInput {
  Future<void> info(String message) {
    return controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.info));
  }
}

final _emitter = _Emitter();
final _db = SqliteDatabaseOutputAdapter(dbName: 'example_logs.db', maxEntries: 200);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final adaptLog = AdaptLog(inputs: [_emitter], outputs: [_db]);
  await adaptLog.initialize();

  runApp(const _ExampleApp());
}

class _ExampleApp extends StatefulWidget {
  const _ExampleApp();

  @override
  State<_ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<_ExampleApp> {
  List<AdaptLogEntry> _entries = const [];

  Future<void> _refresh() async {
    final entries = await _db.getLogs(limit: 50);
    setState(() => _entries = entries);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('adapt_log: SQLite')),
        body: ListView(
          children: [
            for (final entry in _entries)
              ListTile(title: Text(entry.message), subtitle: Text('${entry.timestamp}')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await _emitter.info('Log gravado em ${DateTime.now()}');
            await _refresh();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
