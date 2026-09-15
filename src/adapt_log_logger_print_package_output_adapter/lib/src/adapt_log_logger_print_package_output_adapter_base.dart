import 'package:adapt_log/adapt_log.dart';
import 'package:logger/logger.dart';

class LoggerPrintOutputAdapter extends AdaptLogOutput {
  final Level level;
  final bool printTime;
  late Logger _logger;

  LoggerPrintOutputAdapter({
    this.level = Level.trace,
    this.printTime = true,
  });

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _logger = Logger(
      printer: PrettyPrinter(methodCount: 8, printTime: printTime),
      level: level,
    );
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    switch (entry.level) {
      case AdaptLogLevel.debug:
        _logger.d(entry.message, time: entry.timestamp, error: entry.stackTrace);
      case AdaptLogLevel.info:
        _logger.i(entry.message, time: entry.timestamp);
      case AdaptLogLevel.warning:
        _logger.w(entry.message, time: entry.timestamp, error: entry.stackTrace);
      case AdaptLogLevel.error:
        _logger.e(entry.message, time: entry.timestamp, error: entry.stackTrace);
    }
  }

  @override
  Future<void> shutdown() async {}
}
