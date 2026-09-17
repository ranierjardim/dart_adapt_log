import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_logger_print_package_output_adapter/adapt_log_logger_print_package_output_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  late TextLogInputAdapter log;
  late MemoryOutput memory;
  late List<Object> errors;
  late AdaptLog adaptLog;

  setUp(() async {
    log = TextLogInputAdapter();
    memory = MemoryOutput();
    errors = [];
    adaptLog = AdaptLog(
      inputs: [log],
      outputs: [LoggerPrintOutputAdapter(output: memory)],
      onError: (error, _, __) => errors.add(error),
    );
    await adaptLog.initialize();
  });

  tearDown(() => adaptLog.shutdown());

  test('imprime todos os níveis, com e sem stack trace, sem falhar', () async {
    await log.debug('d');
    await log.info('i');
    await log.warning('w', stackTrace: StackTrace.current);
    await log.error('e', stackTrace: StackTrace.current);
    await log.error('e sem stack');

    expect(errors, isEmpty);
    expect(memory.buffer.map((e) => e.level), [
      Level.debug,
      Level.info,
      Level.warning,
      Level.error,
      Level.error,
    ]);
  });

  test('stack trace da entry aparece na saída', () async {
    await log.error('falhou', stackTrace: StackTrace.current);

    final lines = memory.buffer.single.lines.join('\n');
    expect(lines, contains('falhou'));
    expect(lines, contains('adapt_log_logger_print_package_output_adapter_test.dart'));
  });

  test('sem stack trace não imprime frames internos do pipeline', () async {
    await log.info('simples');

    final lines = memory.buffer.single.lines.join('\n');
    expect(lines, contains('simples'));
    expect(lines, isNot(contains('adapt_log_controller')));
  });

  test('respeita o nível mínimo', () async {
    final quiet = MemoryOutput();
    final quietLog = AdaptLog(
      inputs: [log = TextLogInputAdapter()],
      outputs: [LoggerPrintOutputAdapter(level: Level.warning, output: quiet)],
    );
    await quietLog.initialize();

    await log.info('ignorado');
    await log.error('exibido');

    expect(quiet.buffer.map((e) => e.level), [Level.error]);
    await quietLog.shutdown();
  });
}
