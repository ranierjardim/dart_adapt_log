/// Constantes do protocolo HTTP/WebSocket entre cliente e servidor.
abstract final class AdaptLogProtocol {
  /// Versão do formato JSON. Incrementa em mudanças incompatíveis.
  static const int version = 1;

  /// `POST`: recebe um [LogBatch]. `GET`: lista entries (painel).
  static const String logsPath = '/v1/logs';

  /// `GET`: lista sessões (painel).
  static const String sessionsPath = '/v1/sessions';

  /// WebSocket: stream de [LogStreamEvent] (painel).
  static const String streamPath = '/v1/stream';

  /// `GET`: verificação de saúde do servidor.
  static const String healthPath = '/health';

  /// Cabeçalho com a chave da API: `Authorization: Bearer <chave>`.
  static const String authorizationHeader = 'authorization';

  /// Cabeçalho com a versão do protocolo usada pelo cliente.
  static const String versionHeader = 'x-adapt-log-protocol';

  /// Parâmetro de query alternativo ao cabeçalho, para o WebSocket do painel.
  static const String apiKeyQueryParameter = 'key';
}
