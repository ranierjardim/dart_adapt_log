import 'package:adapt_log/adapt_log.dart';

/// Uma entry armazenada, com o projeto e a sessão de origem.
class LogRecord {
  /// Posição de chegada no servidor; cresce monotonicamente por projeto e
  /// serve de cursor de paginação.
  final int seq;
  final String project;
  final String sessionId;
  final DateTime receivedAt;
  final AdaptLogEntry entry;

  const LogRecord({
    required this.seq,
    required this.project,
    required this.sessionId,
    required this.receivedAt,
    required this.entry,
  });

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'sessionId': sessionId,
        'receivedAt': receivedAt.toUtc().toIso8601String(),
        ...entry.toJson(),
      };
}
