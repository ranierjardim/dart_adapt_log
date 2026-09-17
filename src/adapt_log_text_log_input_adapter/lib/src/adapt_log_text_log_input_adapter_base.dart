import 'package:adapt_log/adapt_log.dart';

/// Input adapter para emissão manual de logs textuais nos quatro níveis.
///
/// Os métodos retornam um `Future` que completa quando todos os outputs
/// processaram a entry; aguardá-lo é opcional e eles nunca lançam por falha
/// de output.
class TextLogInputAdapter extends AdaptLogInput {
  Future<void> debug(String message, {Map<String, dynamic>? metadata}) {
    return _log(message, AdaptLogLevel.debug, metadata: metadata);
  }

  Future<void> info(String message, {Map<String, dynamic>? metadata}) {
    return _log(message, AdaptLogLevel.info, metadata: metadata);
  }

  Future<void> warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    return _log(message, AdaptLogLevel.warning, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    return _log(message, AdaptLogLevel.error, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  Future<void> _log(
    String message,
    AdaptLogLevel level, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    return controller.log(AdaptLogEntry(
      message: message,
      level: level,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    ));
  }
}
