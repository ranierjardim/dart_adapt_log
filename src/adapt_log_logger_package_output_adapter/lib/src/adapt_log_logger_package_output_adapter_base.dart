import 'package:adapt_log/adapt_log.dart';
import 'package:logger/logger.dart';

class AdaptLogLoggerPackageOutputAdapter extends AdaptLogOutputPort {

  late final PrettyPrinter prettyPrinter;
  late final Logger logger;

  @override
  Future<void> initialize(AdaptLogController adaptLogController) async {
    prettyPrinter = PrettyPrinter(methodCount: 0);
    logger = Logger(printer: prettyPrinter, level: Level.verbose, output: null, filter: null);
  }

  @override
  Future<void> onNewLog(AdaptLogObjectMixin object) async {
    if(object is AdaptLogDefaultTextInputObjectMixin && object.shouldPrint) {
      switch(object.defaultTextInputLevel) {
        case AdaptLogDefaultTextInputLevel.shout:
          logger.log(Level.wtf, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        case AdaptLogDefaultTextInputLevel.severe:
          logger.log(Level.warning, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        case AdaptLogDefaultTextInputLevel.warning:
          logger.log(Level.warning, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        case AdaptLogDefaultTextInputLevel.info:
          logger.log(Level.info, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        case AdaptLogDefaultTextInputLevel.config:
          logger.log(Level.info, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        case AdaptLogDefaultTextInputLevel.fine:
          logger.log(Level.verbose, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        case AdaptLogDefaultTextInputLevel.finer:
          logger.log(Level.verbose, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        case AdaptLogDefaultTextInputLevel.finest:
          logger.log(Level.verbose, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
          break;
        default:
          logger.log(Level.wtf, '[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}');
      }
    } else {
      logger.log(Level.info, '[${object.currentTime}]: ${object.toLogString}');
    }
  }

  @override
  Future<void> shutdown() async {

  }
}