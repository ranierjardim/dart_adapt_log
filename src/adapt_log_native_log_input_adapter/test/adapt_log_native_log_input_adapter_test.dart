import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_native_log_input_adapter/adapt_log_native_log_input_adapter.dart';
import 'package:test/test.dart';

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

void main() {
  test('inicializa e encerra sem emitir entries (ponte nativa pendente)', () async {
    final out = Collector();
    final adaptLog = AdaptLog(inputs: [NativeLogInputAdapter()], outputs: [out]);

    await adaptLog.initialize();
    await adaptLog.shutdown();

    expect(out.entries, isEmpty);
  });
}
