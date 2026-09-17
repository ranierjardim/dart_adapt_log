// ignore_for_file: avoid_print

import 'dart:async';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_print_log_input_adapter/adapt_log_flutter_print_log_input_adapter.dart';
import 'package:flutter/material.dart';

/// Output que guarda as últimas linhas capturadas para exibir na tela.
class _RecentLinesOutput extends AdaptLogOutput {
  final lines = ValueNotifier<List<String>>(const []);

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    lines.value = [...lines.value.take(19), entry.message];
  }
}

final _output = _RecentLinesOutput();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final printAdapter = FlutterPrintLogInputAdapter();
  final adaptLog = AdaptLog(inputs: [printAdapter], outputs: [_output]);
  await adaptLog.initialize();

  runZoned(
    () => runApp(const _ExampleApp()),
    zoneSpecification: printAdapter.zoneSpecification,
  );
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('adapt_log: print capturado')),
        body: ValueListenableBuilder<List<String>>(
          valueListenable: _output.lines,
          builder: (context, lines, _) => ListView(
            children: [for (final line in lines) ListTile(title: Text(line))],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('print() em ${DateTime.now()}');
            debugPrint('debugPrint() em ${DateTime.now()}');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
