import 'package:adapt_log/adapt_log.dart';

/// Transmite logs ao adapt_log_server em tempo real.
/// Usa adapt_log_sqlite_database_output_adapter como buffer local para garantia
/// de entrega mesmo quando o servidor está offline.
///
/// CLOSED SOURCE — disponível via assinatura.
class RealTimeRemoteLogOutputAdapter extends AdaptLogOutput {
  final String serverUrl;
  final String apiKey;

  RealTimeRemoteLogOutputAdapter({
    required this.serverUrl,
    required this.apiKey,
  });

  @override
  Future<void> initialize(AdaptLogController controller) async {
    // TODO: Establish WebSocket/HTTP connection to adapt_log_server.
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    // TODO: Serialize entry and transmit to server.
    // Local SQLite buffer (adapt_log_sqlite_database_output_adapter) must be
    // registered as an output alongside this adapter to ensure delivery on reconnect.
  }

  @override
  Future<void> shutdown() async {
    // TODO: Close WebSocket/HTTP connection.
  }
}
