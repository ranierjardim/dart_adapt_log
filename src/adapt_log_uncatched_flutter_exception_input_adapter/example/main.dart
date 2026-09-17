import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_uncatched_flutter_exception_input_adapter/adapt_log_uncatched_flutter_exception_input_adapter.dart';
import 'package:flutter/material.dart';

/// Output que guarda os erros capturados para exibir na tela.
class _ErrorsOutput extends AdaptLogOutput {
  final entries = ValueNotifier<List<AdaptLogEntry>>(const []);

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    entries.value = [entry, ...entries.value.take(19)];
  }
}

final _output = _ErrorsOutput();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final adaptLog = AdaptLog(
    inputs: [UncatchedFlutterExceptionInputAdapter()],
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
        appBar: AppBar(title: const Text('adapt_log: exceções não tratadas')),
        body: ValueListenableBuilder<List<AdaptLogEntry>>(
          valueListenable: _output.entries,
          builder: (context, entries, _) => ListView(
            children: [
              for (final entry in entries)
                ListTile(
                  title: Text(entry.message),
                  subtitle: Text('origem: ${entry.metadata['source']}'),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          // Erro assíncrono não tratado: chega via PlatformDispatcher.onError.
          onPressed: () => Future<void>.error(StateError('erro assíncrono de exemplo')),
          child: const Icon(Icons.bug_report),
        ),
      ),
    );
  }
}
