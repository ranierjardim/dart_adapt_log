import 'package:adapt_log/adapt_log.dart';

/// Evento enviado pelo servidor ao painel pelo WebSocket a cada entry aceita.
class LogStreamEvent {
  static const String type = 'entry';

  final String project;
  final String sessionId;
  final AdaptLogEntry entry;

  const LogStreamEvent({
    required this.project,
    required this.sessionId,
    required this.entry,
  });

  factory LogStreamEvent.fromJson(Map<String, dynamic> json) {
    if (json['type'] != type) {
      throw FormatException('evento desconhecido: ${json['type']}');
    }
    return LogStreamEvent(
      project: json['project'] as String,
      sessionId: json['sessionId'] as String,
      entry: AdaptLogEntry.fromJson(Map<String, dynamic>.from(json['entry'] as Map)),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'project': project,
        'sessionId': sessionId,
        'entry': entry.toJson(),
      };
}
