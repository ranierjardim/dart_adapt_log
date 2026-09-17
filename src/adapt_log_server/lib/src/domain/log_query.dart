import 'package:adapt_log/adapt_log.dart';

/// Filtros de consulta de entries de um projeto. Resultados vêm das mais
/// recentes para as mais antigas; [beforeSeq] pagina a partir de um cursor.
class LogQuery {
  static const int defaultLimit = 100;
  static const int maxLimit = 1000;

  final String project;
  final AdaptLogLevel? level;
  final String? sessionId;

  /// Trecho procurado na mensagem, sem distinção de maiúsculas.
  final String? search;
  final int? beforeSeq;
  final int limit;

  LogQuery({
    required this.project,
    this.level,
    this.sessionId,
    this.search,
    this.beforeSeq,
    int limit = defaultLimit,
  }) : limit = limit.clamp(1, maxLimit);
}
