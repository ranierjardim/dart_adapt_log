import 'dart:convert';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('LogBatch faz ida e volta em JSON, inclusive por jsonEncode', () {
    final session = SessionInfo(
      id: 's1',
      startedAt: DateTime(2026, 9, 15, 10),
      metadata: {'app.version': '1.0.0'},
    );
    final batch = LogBatch(session: session, entries: [
      AdaptLogEntry(message: 'a', level: AdaptLogLevel.info),
      AdaptLogEntry(message: 'b', level: AdaptLogLevel.error, error: ArgumentError('x')),
    ]);

    final decoded = LogBatch.fromJson(jsonDecode(jsonEncode(batch.toJson())) as Map<String, dynamic>);

    expect(decoded.session.id, 's1');
    expect(decoded.session.startedAt, session.startedAt.toUtc());
    expect(decoded.session.metadata, {'app.version': '1.0.0'});
    expect(decoded.entries.map((e) => e.id), batch.entries.map((e) => e.id));
    expect(decoded.entries.last.errorType, 'ArgumentError');
  });

  test('LogBatch rejeita versão de protocolo diferente e corpo malformado', () {
    expect(
      () => LogBatch.fromJson({'protocolVersion': 99, 'session': {}, 'entries': []}),
      throwsFormatException,
    );
    expect(
      () => LogBatch.fromJson({'protocolVersion': AdaptLogProtocol.version}),
      throwsFormatException,
    );
  });

  test('LogStreamEvent faz ida e volta e rejeita tipo desconhecido', () {
    final event = LogStreamEvent(
      project: 'p',
      sessionId: 's',
      entry: AdaptLogEntry(message: 'x', level: AdaptLogLevel.warning),
    );

    final decoded = LogStreamEvent.fromJson(jsonDecode(jsonEncode(event.toJson())) as Map<String, dynamic>);

    expect(decoded.project, 'p');
    expect(decoded.sessionId, 's');
    expect(decoded.entry.id, event.entry.id);
    expect(() => LogStreamEvent.fromJson({'type': 'other'}), throwsFormatException);
  });
}
