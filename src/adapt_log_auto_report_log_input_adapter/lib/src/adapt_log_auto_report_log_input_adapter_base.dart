import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';

/// Monitora o fluxo de logs e dispara um report completo automaticamente
/// toda vez que uma entrada de nível error é detectada.
///
/// Requer que ReportLogInputAdapter já esteja registrado em AdaptLog.inputs
/// e que adapt_log_real_time_remote_log_output_adapter (pago) esteja em outputs
/// para a transmissão ao servidor funcionar.
class AutoReportLogInputAdapter extends AdaptLogInput {
  final ReportLogInputAdapter reportAdapter;

  AutoReportLogInputAdapter({required this.reportAdapter});

  @override
  Future<void> initialize(AdaptLogController controller) async {}

  @override
  Future<void> shutdown() async {}

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    if (entry.level == AdaptLogLevel.error &&
        entry.metadata['isReport'] != true) {
      // Fire-and-forget: não bloqueia o pipeline de log
      reportAdapter.sendReport(context: entry.message);
    }
    return entry;
  }
}
