import 'dart:convert';
import 'dart:typed_data';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_error_screenshot_input_adapter/adapt_log_flutter_error_screenshot_input_adapter.dart';
import 'package:flutter/material.dart';

class _Emitter extends AdaptLogInput {
  Future<void> error(String message) {
    return controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.error));
  }
}

/// Guarda a última screenshot recebida para exibi-la na própria tela. Em
/// produção, aqui entra o adapter remoto, que a envia ao painel.
class _LastScreenshotOutput extends AdaptLogOutput {
  final last = ValueNotifier<Uint8List?>(null);

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    final data = entry.metadata[FlutterErrorScreenshotInputAdapter.screenshotKey];
    if (data is String) last.value = base64Decode(data);
  }
}

final _emitter = _Emitter();
final _screenshot = FlutterErrorScreenshotInputAdapter(minInterval: Duration.zero);
final _output = _LastScreenshotOutput();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adaptLog = AdaptLog(inputs: [_emitter, _screenshot], outputs: [_output]);
  await adaptLog.initialize();
  runApp(AdaptLogScreenshotBoundary(adapter: _screenshot, child: const _ExampleApp()));
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('adapt_log: screenshot no erro')),
        body: Center(
          child: ValueListenableBuilder<Uint8List?>(
            valueListenable: _output.last,
            builder: (context, bytes, _) => bytes == null
                ? const Text('Toque no botão para simular um erro.')
                : Image.memory(bytes, width: 240),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _emitter.error('Falha simulada às ${DateTime.now()}'),
          child: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }
}
