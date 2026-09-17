import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_auto_report_log_input_adapter/adapt_log_auto_report_log_input_adapter.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';

class _ConsolePrint extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    print('[${entry.level.name}] ${entry.message}');
  }
}

class _Emitter extends AdaptLogInput {
  Future<void> error(String message) {
    return controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.error));
  }
}

Future<void> main() async {
  final emitter = _Emitter();
  final report = ReportLogInputAdapter();
  final adaptLog = AdaptLog(
    inputs: [emitter, report, AutoReportLogInputAdapter(reportAdapter: report)],
    outputs: [_ConsolePrint()],
  );
  await adaptLog.initialize();

  // O erro é impresso e, logo depois, o report disparado automaticamente.
  await emitter.error('Falha crítica no checkout');
  await adaptLog.flush();

  await adaptLog.shutdown();
}
