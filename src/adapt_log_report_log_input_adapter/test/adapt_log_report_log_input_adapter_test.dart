import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:test/test.dart';

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

class Slow extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) {
    return Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('emite entry info marcada como report com o contexto', () async {
    final report = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(inputs: [report], outputs: [out]);
    await adaptLog.initialize();

    expect(await report.sendReport(context: 'checkout', data: {'reportFor': 'abc'}), isTrue);

    final entry = out.entries.single;
    expect(entry.level, AdaptLogLevel.info);
    expect(entry.message, 'Report: checkout');
    expect(entry.metadata['isReport'], isTrue);
    expect(entry.metadata['reportContext'], 'checkout');
    expect(entry.metadata['reportFor'], 'abc');
    expect(entry.metadata['reportTimestamp'], isA<String>());
    await adaptLog.shutdown();
  });

  test('coalesce reports enquanto um ainda está em andamento', () async {
    final report = ReportLogInputAdapter();
    final adaptLog = AdaptLog(inputs: [report], outputs: [Slow()]);
    await adaptLog.initialize();

    final first = report.sendReport(context: 'a');
    expect(report.isSending, isTrue);
    final second = report.sendReport(context: 'b');

    expect(await second, isFalse);
    expect(await first, isTrue);
    expect(report.isSending, isFalse);
    await adaptLog.shutdown();
  });
}
