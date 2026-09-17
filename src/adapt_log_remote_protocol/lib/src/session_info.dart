/// Identifica uma execução da aplicação cliente. Criada uma vez por
/// inicialização do adapter remoto.
class SessionInfo {
  final String id;
  final DateTime startedAt;

  /// Informações fixas da sessão (app, dispositivo, usuário...).
  final Map<String, dynamic> metadata;

  SessionInfo({
    required this.id,
    required DateTime startedAt,
    Map<String, dynamic>? metadata,
  })  : startedAt = startedAt.toUtc(),
        metadata = metadata == null || metadata.isEmpty
            ? const {}
            : Map<String, dynamic>.unmodifiable(metadata);

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return SessionInfo(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      metadata: metadata is Map ? Map<String, dynamic>.from(metadata) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'metadata': metadata,
      };
}
