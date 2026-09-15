import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:flutter/foundation.dart';

/// Monitora o fluxo de logs e, ao detectar um erro, dispara um report
/// completo incluindo os prints Flutter recentes capturados via debugPrint.
///
/// Requer que [ReportLogInputAdapter] já esteja registrado em AdaptLog.inputs
/// e que adapt_log_real_time_remote_log_output_adapter (pago) esteja em outputs
/// para a transmissão ao servidor funcionar.
class FlutterAutoReportLogInputAdapter extends AdaptLogInput {
  final ReportLogInputAdapter reportAdapter;

  /// Número máximo de linhas de print mantidas no buffer circular.
  final int maxPrintBuffer;

  final _printBuffer = <String>[];
  late DebugPrintCallback _originalDebugPrint;

  FlutterAutoReportLogInputAdapter({
    required this.reportAdapter,
    this.maxPrintBuffer = 50,
  });

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _originalDebugPrint = debugPrint;

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        _printBuffer.add(message);
        if (_printBuffer.length > maxPrintBuffer) {
          _printBuffer.removeAt(0);
        }
      }
      _originalDebugPrint(message, wrapWidth: wrapWidth);
    };
  }

  @override
  Future<void> shutdown() async {
    debugPrint = _originalDebugPrint;
    _printBuffer.clear();
  }

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    if (entry.level == AdaptLogLevel.error &&
        entry.metadata['isReport'] != true) {
      final prints = List<String>.from(_printBuffer);
      final contextParts = [
        entry.message,
        if (prints.isNotEmpty)
          '\nFlutter output (últimas ${prints.length} linhas):\n${prints.map((p) => '  $p').join('\n')}',
      ];
      // Fire-and-forget: não bloqueia o pipeline de log
      reportAdapter.sendReport(context: contextParts.join('\n'));
    }
    return entry;
  }
}
