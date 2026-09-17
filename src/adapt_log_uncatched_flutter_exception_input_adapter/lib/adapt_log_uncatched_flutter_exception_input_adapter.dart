library adapt_log_uncatched_flutter_exception_input_adapter;

import 'dart:ui';

import 'package:adapt_log/adapt_log.dart';
import 'package:flutter/foundation.dart';

/// Captura exceções não tratadas e as registra como entries de nível `error`,
/// com `metadata['source']` indicando a origem.
///
/// Hooks instalados em [initialize] e restaurados em [shutdown]:
/// - `FlutterError.onError`: erros do framework (build, layout, gestos...);
/// - `PlatformDispatcher.instance.onError`: erros assíncronos não tratados no
///   isolate raiz (Flutter 3.3+).
///
/// Os handlers anteriores continuam sendo chamados depois do registro, então o
/// comportamento padrão, como imprimir o erro no console, é preservado.
///
/// Não envolva a app em `runZonedGuarded` só para "cobrir" este adapter: erros
/// capturados por essa zona nunca chegam a `PlatformDispatcher.onError`. Se a
/// app já usa `runZonedGuarded`, encaminhe pelo handler dela:
///
/// ```dart
/// runZonedGuarded(() => runApp(const MyApp()), adapter.handleUncaughtError);
/// ```
class UncatchedFlutterExceptionInputAdapter extends AdaptLogInput {
  FlutterExceptionHandler? _originalOnError;
  FlutterExceptionHandler? _onErrorHook;
  ErrorCallback? _originalOnPlatformError;
  ErrorCallback? _onPlatformErrorHook;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);

    final originalOnError = _originalOnError = FlutterError.onError;
    FlutterError.onError = _onErrorHook = (FlutterErrorDetails details) {
      _dispatch(details.exceptionAsString(), details.exception, details.stack, source: 'FlutterError');
      if (originalOnError != null) {
        originalOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final originalOnPlatformError = _originalOnPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = _onPlatformErrorHook = (Object error, StackTrace stack) {
      _dispatch(error.toString(), error, stack, source: 'PlatformDispatcher');
      // Sem handler anterior, `false` mantém o fallback padrão da plataforma.
      return originalOnPlatformError?.call(error, stack) ?? false;
    };
  }

  @override
  Future<void> shutdown() async {
    // Só restaura se nenhum outro hook foi instalado por cima do nosso.
    if (identical(FlutterError.onError, _onErrorHook)) {
      FlutterError.onError = _originalOnError;
    }
    if (identical(PlatformDispatcher.instance.onError, _onPlatformErrorHook)) {
      PlatformDispatcher.instance.onError = _originalOnPlatformError;
    }
    _onErrorHook = null;
    _originalOnError = null;
    _onPlatformErrorHook = null;
    _originalOnPlatformError = null;
    await super.shutdown();
  }

  /// Registra um erro não tratado vindo de fora dos hooks, por exemplo do
  /// handler de `runZonedGuarded`. Antes de [initialize] o erro é encaminhado
  /// a `FlutterError.reportError` para não se perder.
  void handleUncaughtError(Object error, StackTrace stackTrace) {
    if (!isAttached) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'adapt_log',
      ));
      return;
    }
    _dispatch(error.toString(), error, stackTrace, source: 'zone');
  }

  void _dispatch(String message, Object? error, StackTrace? stack, {required String source}) {
    if (!isAttached) return;
    controller.log(AdaptLogEntry(
      message: message,
      level: AdaptLogLevel.error,
      error: error,
      stackTrace: stack,
      metadata: {'source': source},
    ));
  }
}
