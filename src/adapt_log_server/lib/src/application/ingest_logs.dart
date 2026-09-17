import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';

import '../domain/log_repository.dart';
import 'log_stream.dart';

class IngestResult {
  /// Entries recebidas no lote.
  final int accepted;

  /// Entries novas, efetivamente gravadas.
  final int stored;

  const IngestResult({required this.accepted, required this.stored});

  Map<String, dynamic> toJson() => {'accepted': accepted, 'stored': stored};
}

/// Caso de uso: receber um lote de um cliente autenticado, gravar e difundir.
class IngestLogs {
  final LogRepository repository;
  final LogStream stream;
  final DateTime Function() now;

  IngestLogs({required this.repository, required this.stream, DateTime Function()? now})
      : now = now ?? DateTime.now;

  Future<IngestResult> call({required String project, required LogBatch batch}) async {
    final stored = await repository.saveBatch(
      project: project,
      session: batch.session,
      entries: batch.entries,
      receivedAt: now().toUtc(),
    );
    for (final record in stored) {
      stream.publish(LogStreamEvent(
        project: project,
        sessionId: record.sessionId,
        entry: record.entry,
      ));
    }
    return IngestResult(accepted: batch.entries.length, stored: stored.length);
  }
}
