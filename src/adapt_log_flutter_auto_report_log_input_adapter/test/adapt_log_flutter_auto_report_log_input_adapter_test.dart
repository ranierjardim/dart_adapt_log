import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_auto_report_log_input_adapter/adapt_log_flutter_auto_report_log_input_adapter.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class Emitter extends AdaptLogInput {
  Future<void> emit(String message, AdaptLogLevel level) {
    return controller.log(AdaptLogEntry(message: message, level: level));
  }
}

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  List<String> get messages => entries.map((e) => e.message).toList();

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

void main() {
  late DebugPrintCallback previousDebugPrint;
  late List<String?> printedByOriginal;

  setUp(() {
    previousDebugPrint = debugPrint;
    printedByOriginal = [];
    debugPrint = (String? message, {int? wrapWidth}) => printedByOriginal.add(message);
  });

  tearDown(() => debugPrint = previousDebugPrint);

  test('report de um erro inclui os últimos debugPrint e a saída original é mantida', () async {
    final emitter = Emitter();
    final report = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(
      inputs: [emitter, report, FlutterAutoReportLogInputAdapter(reportAdapter: report, maxPrintBuffer: 2)],
      outputs: [out],
    );
    await adaptLog.initialize();

    debugPrint('linha 1');
    debugPrint('linha 2');
    debugPrint('linha 3');
    await emitter.emit('boom', AdaptLogLevel.error);
    await adaptLog.flush();

    expect(printedByOriginal, ['linha 1', 'linha 2', 'linha 3']);
    expect(out.messages, ['boom', 'Report: boom\n\nFlutter output (últimas 2 linhas):\n  linha 2\n  linha 3']);
    expect(out.entries.first.metadata['recentPrints'], ['linha 2', 'linha 3']);
    expect(out.entries.last.metadata['isReport'], isTrue);
    expect(out.entries.last.metadata['reportFor'], out.entries.first.id);
    await adaptLog.shutdown();
  });

  test('sem prints no buffer o contexto é só a mensagem', () async {
    final emitter = Emitter();
    final report = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(
      inputs: [emitter, report, FlutterAutoReportLogInputAdapter(reportAdapter: report)],
      outputs: [out],
    );
    await adaptLog.initialize();

    await emitter.emit('boom', AdaptLogLevel.error);
    await adaptLog.flush();

    expect(out.messages.last, 'Report: boom');
    await adaptLog.shutdown();
  });

  test('não dispara report para info nem para entries que já são report', () async {
    final emitter = Emitter();
    final report = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(
      inputs: [emitter, report, FlutterAutoReportLogInputAdapter(reportAdapter: report)],
      outputs: [out],
    );
    await adaptLog.initialize();

    await emitter.emit('info', AdaptLogLevel.info);
    await report.sendReport(context: 'manual');
    await adaptLog.flush();

    expect(out.messages, ['info', 'Report: manual']);
    await adaptLog.shutdown();
  });

  test('shutdown restaura o debugPrint anterior e limpa o buffer', () async {
    final before = debugPrint;
    final report = ReportLogInputAdapter();
    final adapter = FlutterAutoReportLogInputAdapter(reportAdapter: report);
    final adaptLog = AdaptLog(inputs: [report, adapter], outputs: const []);
    await adaptLog.initialize();
    debugPrint('x');
    expect(adapter.recentPrints, ['x']);

    await adaptLog.shutdown();

    expect(identical(debugPrint, before), isTrue);
    expect(adapter.recentPrints, isEmpty);
  });
}
