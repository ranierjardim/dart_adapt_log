import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';

import 'log_query.dart';
import 'log_record.dart';
import 'session_record.dart';
import 'stored_screenshot.dart';

/// Port de armazenamento do servidor.
abstract class LogRepository {
  /// Grava as entries de um lote e atualiza a sessão. Entries já conhecidas
  /// (mesmo `id` no mesmo projeto) são ignoradas. Retorna só as gravadas.
  Future<List<LogRecord>> saveBatch({
    required String project,
    required SessionInfo session,
    required List<AdaptLogEntry> entries,
    required DateTime receivedAt,
  });

  Future<List<LogRecord>> query(LogQuery query);

  Future<LogRecord?> findByEntryId(String project, String entryId);

  Future<List<SessionRecord>> sessions(String project, {int limit = 100});

  /// Screenshot pelo id da própria entry de screenshot ou pelo id da entry
  /// de erro à qual ela se refere.
  Future<StoredScreenshot?> findScreenshot(String project, String entryId);

  Future<void> close();
}
