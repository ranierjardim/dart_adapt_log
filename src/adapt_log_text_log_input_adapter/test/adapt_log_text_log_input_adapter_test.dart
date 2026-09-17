import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';
import 'package:test/test.dart';

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

void main() {
  late TextLogInputAdapter log;
  late Collector out;
  late AdaptLog adaptLog;

  setUp(() async {
    log = TextLogInputAdapter();
    out = Collector();
    adaptLog = AdaptLog(inputs: [log], outputs: [out]);
    await adaptLog.initialize();
  });

  tearDown(() => adaptLog.shutdown());

  test('emite cada nível com a mensagem correta', () async {
    await log.debug('d');
    await log.info('i');
    await log.warning('w');
    await log.error('e');

    expect(out.entries.map((e) => e.level), [
      AdaptLogLevel.debug,
      AdaptLogLevel.info,
      AdaptLogLevel.warning,
      AdaptLogLevel.error,
    ]);
    expect(out.entries.map((e) => e.message), ['d', 'i', 'w', 'e']);
  });

  test('repassa error, stack trace e metadata', () async {
    final stack = StackTrace.current;
    final failure = StateError('estado ruim');
    await log.error('falhou', error: failure, stackTrace: stack, metadata: {'userId': 42});

    final entry = out.entries.single;
    expect(entry.error, same(failure));
    expect(entry.errorType, 'StateError');
    expect(entry.stackTrace, same(stack));
    expect(entry.metadata, {'userId': 42});
  });

  test('antes de initialize lança StateError claro', () {
    expect(() => TextLogInputAdapter().info('cedo'), throwsA(isA<StateError>()));
  });
}
