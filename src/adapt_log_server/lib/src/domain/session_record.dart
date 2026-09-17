/// Uma sessão de cliente vista pelo servidor, com contadores agregados.
class SessionRecord {
  final String id;
  final String project;
  final DateTime startedAt;
  final DateTime lastSeenAt;
  final Map<String, dynamic> metadata;
  final int entryCount;
  final int errorCount;

  const SessionRecord({
    required this.id,
    required this.project,
    required this.startedAt,
    required this.lastSeenAt,
    required this.metadata,
    required this.entryCount,
    required this.errorCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'lastSeenAt': lastSeenAt.toUtc().toIso8601String(),
        'metadata': metadata,
        'entryCount': entryCount,
        'errorCount': errorCount,
      };
}
