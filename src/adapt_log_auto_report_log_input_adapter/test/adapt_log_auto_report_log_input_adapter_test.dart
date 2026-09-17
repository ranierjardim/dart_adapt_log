import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_auto_report_log_input_adapter/adapt_log_auto_report_log_input_adapter.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:test/test.dart';

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
  test('dispara um report depois de cada erro, nunca de info/warning', () async {
    final emitter = Emitter();
    final report = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(
      inputs: [emitter, report, AutoReportLogInputAdapter(reportAdapter: report)],
      outputs: [out],
    );
    await adaptLog.initialize();

    await emitter.emit('info', AdaptLogLevel.info);
    await emitter.emit('aviso', AdaptLogLevel.warning);
    await emitter.emit('boom', AdaptLogLevel.error);
    await adaptLog.flush();

    expect(out.messages, ['info', 'aviso', 'boom', 'Report: boom']);
    expect(out.entries.last.metadata['isReport'], isTrue);
    expect(out.entries.last.metadata['reportFor'], out.entries[2].id);
    await adaptLog.shutdown();
  });

  test('um report não dispara outro report', () async {
    final report = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(
      inputs: [report, AutoReportLogInputAdapter(reportAdapter: report)],
      outputs: [out],
    );
    await adaptLog.initialize();

    await report.sendReport(context: 'manual');
    await adaptLog.flush();

    expect(out.messages, ['Report: manual']);
    await adaptLog.shutdown();
  });

  test('report adapter não registrado: erro vai para onError e a entry segue', () async {
    final errors = <Object>[];
    final emitter = Emitter();
    final orphan = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(
      inputs: [emitter, AutoReportLogInputAdapter(reportAdapter: orphan)],
      outputs: [out],
      onError: (error, _, __) => errors.add(error),
    );
    await adaptLog.initialize();

    await emitter.emit('boom', AdaptLogLevel.error);
    await adaptLog.flush();
    await Future<void>.delayed(Duration.zero);

    expect(out.messages, ['boom']);
    expect(errors.single, isA<StateError>());
    await adaptLog.shutdown();
  });

  test('buildReportContext pode ser sobrescrito', () async {
    final emitter = Emitter();
    final report = ReportLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(
      inputs: [emitter, report, _Prefixed(reportAdapter: report)],
      outputs: [out],
    );
    await adaptLog.initialize();

    await emitter.emit('boom', AdaptLogLevel.error);
    await adaptLog.flush();

    expect(out.messages.last, 'Report: [ctx] boom');
    await adaptLog.shutdown();
  });
}

class _Prefixed extends AutoReportLogInputAdapter {
  _Prefixed({required super.reportAdapter});

  @override
  String buildReportContext(AdaptLogEntry entry) => '[ctx] ${entry.message}';
}
