import 'package:adapt_log/adapt_log.dart';

// Mostra como ligar o adapt_log a adapters próprios. Para implementações
// prontas use adapt_log_text_log_input_adapter e
// adapt_log_logger_print_package_output_adapter.

class _ExampleInputAdapter extends AdaptLogInput {
  Future<void> info(String message) {
    return controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.info));
  }
}

class _ExampleOutputAdapter extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    print('[${entry.level.name.toUpperCase()}][${entry.timestamp}]: ${entry.message}');
  }
}

Future<void> main() async {
  final input = _ExampleInputAdapter();
  final output = _ExampleOutputAdapter();

  final adaptLog = AdaptLog(inputs: [input], outputs: [output]);
  await adaptLog.initialize();

  await input.info('adapt_log running!');

  await adaptLog.shutdown();
}
