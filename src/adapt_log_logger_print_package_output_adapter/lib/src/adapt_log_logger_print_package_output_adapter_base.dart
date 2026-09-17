import 'package:adapt_log/adapt_log.dart';
import 'package:logger/logger.dart';

/// Exibe as entries no console com o `PrettyPrinter` do package `logger`.
class LoggerPrintOutputAdapter extends AdaptLogOutput {
  /// Nível mínimo exibido, na escala do package `logger`.
  final Level level;

  /// Formato do timestamp. Use [DateTimeFormat.none] para omitir.
  final DateTimeFormatter dateTimeFormat;

  /// Quantidade máxima de frames impressos do stack trace da entry. Entries
  /// sem stack trace não imprimem frame nenhum.
  final int stackTraceMethodCount;

  /// Destino das linhas. Padrão: console.
  final LogOutput? output;

  /// Filtro do package `logger`. O padrão, [ProductionFilter], imprime em
  /// qualquer modo de execução respeitando [level]; o [DevelopmentFilter]
  /// padrão do `logger` só imprime com asserts habilitados.
  final LogFilter? filter;

  late final Logger _logger = Logger(
    printer: _EntryAwarePrinter(
      withStackTrace: PrettyPrinter(
        methodCount: stackTraceMethodCount,
        dateTimeFormat: dateTimeFormat,
      ),
      withoutStackTrace: PrettyPrinter(
        methodCount: 0,
        dateTimeFormat: dateTimeFormat,
      ),
    ),
    level: level,
    output: output,
    filter: filter ?? ProductionFilter(),
  );

  LoggerPrintOutputAdapter({
    this.level = Level.trace,
    this.dateTimeFormat = DateTimeFormat.onlyTimeAndSinceStart,
    this.stackTraceMethodCount = 8,
    this.output,
    this.filter,
  });

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    switch (entry.level) {
      case AdaptLogLevel.debug:
        _logger.d(entry.message, time: entry.timestamp, stackTrace: entry.stackTrace);
      case AdaptLogLevel.info:
        _logger.i(entry.message, time: entry.timestamp, stackTrace: entry.stackTrace);
      case AdaptLogLevel.warning:
        _logger.w(entry.message, time: entry.timestamp, stackTrace: entry.stackTrace);
      case AdaptLogLevel.error:
        _logger.e(entry.message, time: entry.timestamp, stackTrace: entry.stackTrace);
    }
  }

  @override
  Future<void> shutdown() async {
    await super.shutdown();
    await _logger.close();
  }
}

/// O `PrettyPrinter` usa `methodCount` tanto para o stack trace informado
/// quanto para `StackTrace.current` quando não há nenhum. Como a chamada vem
/// de dentro do pipeline, o stack "atual" só teria frames internos do
/// adapt_log; por isso um printer sem frames é usado nesse caso.
class _EntryAwarePrinter extends LogPrinter {
  final PrettyPrinter withStackTrace;
  final PrettyPrinter withoutStackTrace;

  _EntryAwarePrinter({required this.withStackTrace, required this.withoutStackTrace});

  @override
  List<String> log(LogEvent event) {
    final printer = event.stackTrace == null ? withoutStackTrace : withStackTrace;
    return printer.log(event);
  }
}
