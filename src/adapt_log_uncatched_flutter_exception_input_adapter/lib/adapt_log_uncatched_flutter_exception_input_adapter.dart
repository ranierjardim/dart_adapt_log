library adapt_log_uncatched_flutter_exception_input_adapter;

import 'dart:ui';

import 'package:adapt_log/adapt_log.dart';
import 'package:flutter/foundation.dart';

/// Captura exceções não tratadas via FlutterError.onError e
/// PlatformDispatcher.instance.onError e as registra como entradas de erro.
///
/// Deve ser inicializado dentro de runZonedGuarded() antes de runApp():
///
/// ```dart
/// void main() {
///   runZonedGuarded(() async {
///     WidgetsFlutterBinding.ensureInitialized();
///     final adapter = UncatchedFlutterExceptionInputAdapter();
///     final adaptLog = AdaptLog(inputs: [adapter], outputs: [...]);
///     await adaptLog.initialize();
///     runApp(const MyApp());
///   }, (error, stack) {
///     // Zona capturada automaticamente pelo adapter
///   });
/// }
/// ```
class UncatchedFlutterExceptionInputAdapter extends AdaptLogInput {
  late AdaptLogController _controller;
  FlutterExceptionHandler? _originalOnError;
  ErrorCallback? _originalOnPlatformError;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
    _originalOnError = FlutterError.onError;
    _originalOnPlatformError = PlatformDispatcher.instance.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      _dispatch(
        details.exceptionAsString(),
        details.stack,
      );
      _originalOnError?.call(details) ?? FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _dispatch(error.toString(), stack);
      return _originalOnPlatformError?.call(error, stack) ?? false;
    };
  }

  @override
  Future<void> shutdown() async {
    FlutterError.onError = _originalOnError;
    PlatformDispatcher.instance.onError = _originalOnPlatformError;
  }

  void _dispatch(String message, StackTrace? stack) {
    _controller.log(AdaptLogEntry(
      message: message,
      level: AdaptLogLevel.error,
      stackTrace: stack,
    ));
  }
}
