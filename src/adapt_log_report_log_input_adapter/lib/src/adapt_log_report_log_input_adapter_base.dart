import 'package:adapt_log/adapt_log.dart';

/// Agrega logs, prints e metadados de contexto em um report estruturado e o
/// encaminha ao adapt_log_real_time_remote_log_output_adapter (pago) para
/// transmissão ao servidor.
class ReportLogInputAdapter extends AdaptLogInput {
  late AdaptLogController _controller;
  bool _sending = false;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
  }

  @override
  Future<void> shutdown() async {}

  /// Envia um report completo com contexto opcional.
  /// Requer adapt_log_real_time_remote_log_output_adapter como output para
  /// transmissão ao servidor.
  Future<void> sendReport({String? context}) async {
    if (_sending) return;
    _sending = true;
    try {
      await _controller.log(AdaptLogEntry(
        message: 'Report: ${context ?? 'manual'}',
        level: AdaptLogLevel.info,
        metadata: {
          'isReport': true,
          if (context != null) 'reportContext': context,
          'reportTimestamp': DateTime.now().toIso8601String(),
        },
      ));
    } finally {
      _sending = false;
    }
  }
}
