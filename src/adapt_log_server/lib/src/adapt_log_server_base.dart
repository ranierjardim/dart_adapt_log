/// Servidor Dart para receber e armazenar logs transmitidos pelos clientes
/// via adapt_log_real_time_remote_log_output_adapter.
///
/// Expõe API HTTP/WebSocket para o painel web consultar e filtrar logs
/// por usuário, sessão e nível.
///
/// CLOSED SOURCE — disponível via assinatura.
///
/// Uso:
/// ```dart
/// final server = AdaptLogServer(port: 8080, dbPath: '/var/data/logs.sqlite');
/// await server.start();
/// ```
class AdaptLogServer {
  final int port;
  final String dbPath;

  AdaptLogServer({
    this.port = 8080,
    required this.dbPath,
  });

  Future<void> start() async {
    // TODO: Initialize SqliteDatabaseOutputAdapter with dbPath.
    // TODO: Start shelf HTTP/WebSocket server on [port].
    // TODO: Expose REST endpoints for log query/filter.
    // TODO: Accept WebSocket connections from RealTimeRemoteLogOutputAdapter.
    throw UnimplementedError('adapt_log_server is a closed-source module.');
  }

  Future<void> stop() async {}
}
