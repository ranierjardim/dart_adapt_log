import 'package:adapt_log/adapt_log.dart';

/// Emite reports: entries de nível `info` marcadas com `metadata.isReport`
/// e o contexto informado. O adapt_log_real_time_remote_log_output_adapter
/// (pago) transmite essa marcação ao servidor, que a exibe no painel.
class ReportLogInputAdapter extends AdaptLogInput {
  bool _sending = false;

  /// Se há um report em andamento neste momento.
  bool get isSending => _sending;

  /// Emite um report com [context] opcional e [data] extra na metadata.
  ///
  /// Enquanto um report ainda não foi processado por todos os outputs, novas
  /// chamadas são coalescidas: retornam `false` sem emitir nada. Retorna
  /// `true` quando o report foi processado.
  Future<bool> sendReport({String? context, Map<String, dynamic>? data}) async {
    if (_sending) return false;
    _sending = true;
    try {
      await controller.log(AdaptLogEntry(
        message: 'Report: ${context ?? 'manual'}',
        level: AdaptLogLevel.info,
        metadata: {
          ...?data,
          'isReport': true,
          if (context != null) 'reportContext': context,
          'reportTimestamp': DateTime.now().toUtc().toIso8601String(),
        },
      ));
      return true;
    } finally {
      _sending = false;
    }
  }
}
