import 'package:adapt_log/adapt_log.dart';

import 'protocol.dart';
import 'session_info.dart';

/// Lote de entries enviado pelo cliente em um `POST /v1/logs`.
class LogBatch {
  final SessionInfo session;
  final List<AdaptLogEntry> entries;

  LogBatch({required this.session, required List<AdaptLogEntry> entries})
      : entries = List<AdaptLogEntry>.unmodifiable(entries);

  /// Lança [FormatException] se a versão do protocolo não for suportada ou
  /// se o corpo não tiver a forma esperada.
  factory LogBatch.fromJson(Map<String, dynamic> json) {
    final version = json['protocolVersion'];
    if (version != AdaptLogProtocol.version) {
      throw FormatException('protocolVersion não suportada: $version');
    }
    final session = json['session'];
    final entries = json['entries'];
    if (session is! Map || entries is! List) {
      throw const FormatException('lote precisa de "session" e "entries"');
    }
    return LogBatch(
      session: SessionInfo.fromJson(Map<String, dynamic>.from(session)),
      entries: [
        for (final entry in entries)
          AdaptLogEntry.fromJson(Map<String, dynamic>.from(entry as Map)),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'protocolVersion': AdaptLogProtocol.version,
        'session': session.toJson(),
        'entries': [for (final entry in entries) entry.toJson()],
      };
}
