import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_auto_report_log_input_adapter/adapt_log_flutter_auto_report_log_input_adapter.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:flutter/material.dart';

class _Emitter extends AdaptLogInput {
  Future<void> error(String message) {
    return controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.error));
  }
}

/// Output que guarda as entries para exibir na tela. Em produção, aqui
/// entram o buffer SQLite e o adapter remoto (pago).
class _ScreenOutput extends AdaptLogOutput {
  final entries = ValueNotifier<List<AdaptLogEntry>>(const []);

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    entries.value = [entry, ...entries.value.take(19)];
  }
}

final _emitter = _Emitter();
final _output = _ScreenOutput();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final report = ReportLogInputAdapter();
  final adaptLog = AdaptLog(
    inputs: [
      _emitter,
      report,
      FlutterAutoReportLogInputAdapter(reportAdapter: report, maxPrintBuffer: 5),
    ],
    outputs: [_output],
  );
  await adaptLog.initialize();

  runApp(const _ExampleApp());
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('adapt_log: auto report')),
        body: ValueListenableBuilder<List<AdaptLogEntry>>(
          valueListenable: _output.entries,
          builder: (context, entries, _) => ListView(
            children: [
              for (final entry in entries)
                ListTile(
                  title: Text('[${entry.level.name}] ${entry.message}'),
                  subtitle: entry.metadata['isReport'] == true ? const Text('report') : null,
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            debugPrint('usuário tocou no botão às ${DateTime.now()}');
            _emitter.error('Falha simulada');
          },
          child: const Icon(Icons.error_outline),
        ),
      ),
    );
  }
}
