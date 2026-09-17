import 'dart:async';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';

/// Observa o pipeline e dispara um report automaticamente a cada entry de
/// nível `error` que não seja, ela própria, um report.
///
/// [reportAdapter] precisa estar registrado em `AdaptLog.inputs`; se não
/// estiver, a falha é reportada em `AdaptLog.onError` e a entry original
/// segue normalmente. O report entra na fila e chega aos outputs depois da
/// entry de erro que o disparou.
class AutoReportLogInputAdapter extends AdaptLogInput {
  final ReportLogInputAdapter reportAdapter;

  AutoReportLogInputAdapter({required this.reportAdapter});

  /// Monta o contexto do report a partir da entry de erro. Sobrescreva para
  /// acrescentar informações.
  String buildReportContext(AdaptLogEntry entry) => entry.message;

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    if (entry.level == AdaptLogLevel.error && entry.metadata['isReport'] != true) {
      final report = reportAdapter.sendReport(
        context: buildReportContext(entry),
        data: {'reportFor': entry.id},
      );
      unawaited(report.then(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          controller.reportError(error, stackTrace, this);
        },
      ));
    }
    return entry;
  }
}
