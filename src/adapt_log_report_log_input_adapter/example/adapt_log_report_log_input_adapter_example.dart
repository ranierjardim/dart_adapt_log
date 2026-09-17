import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';

class _ConsolePrint extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    print('[${entry.level.name}] ${entry.message} ${entry.metadata}');
  }
}

Future<void> main() async {
  final report = ReportLogInputAdapter();
  final adaptLog = AdaptLog(inputs: [report], outputs: [_ConsolePrint()]);
  await adaptLog.initialize();

  final sent = await report.sendReport(context: 'Tela de pagamento');
  print('report enviado: $sent');

  await adaptLog.shutdown();
}
