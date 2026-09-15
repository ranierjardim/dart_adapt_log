// ignore_for_file: unused_local_variable

import 'package:adapt_log/adapt_log.dart';

// Example showing how to wire adapt_log with custom adapters.
// Use adapt_log_text_log_input_adapter and adapt_log_logger_print_package_output_adapter
// for ready-to-use implementations.

class _ExampleInputAdapter extends AdaptLogInput {
  late AdaptLogController _controller;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
  }

  @override
  Future<void> shutdown() async {}

  Future<void> info(String message) async {
    await _controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.info));
  }
}

class _ExampleOutputAdapter extends AdaptLogOutput {
  @override
  Future<void> initialize(AdaptLogController controller) async {}

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    print('[${entry.level.name.toUpperCase()}][${entry.timestamp}]: ${entry.message}');
  }

  @override
  Future<void> shutdown() async {}
}

Future<void> main() async {
  final input = _ExampleInputAdapter();
  final output = _ExampleOutputAdapter();

  final adaptLog = AdaptLog(inputs: [input], outputs: [output]);
  await adaptLog.initialize();

  await input.info('adapt_log running!');
}
