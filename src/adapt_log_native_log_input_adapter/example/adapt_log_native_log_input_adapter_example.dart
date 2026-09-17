import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_native_log_input_adapter/adapt_log_native_log_input_adapter.dart';

class _ConsolePrint extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    print('[${entry.level.name}] ${entry.message}');
  }
}

Future<void> main() async {
  final adaptLog = AdaptLog(
    inputs: [NativeLogInputAdapter()],
    outputs: [_ConsolePrint()],
  );
  await adaptLog.initialize();
  // Quando a ponte nativa existir, logs do SO chegarão aqui automaticamente.
  await adaptLog.shutdown();
}
