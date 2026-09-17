import 'dart:async';

import 'adapt_log_adapter.dart';
import 'adapt_log_controller.dart';
import 'adapt_log_input.dart';
import 'adapt_log_output.dart';

/// Recebe as falhas de adapters (em `initialize`, `enrichEntry`, `onNewLog`
/// ou `shutdown`). Não deve lançar.
typedef AdaptLogErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
  AdaptLogAdapter adapter,
);

enum AdaptLogState { created, initializing, ready, shuttingDown, shutDown }

/// Orquestrador: registra inputs e outputs e gerencia o ciclo de vida.
///
/// ```dart
/// final adaptLog = AdaptLog(inputs: [...], outputs: [...]);
/// await adaptLog.initialize();
/// // ...
/// await adaptLog.shutdown();
/// ```
class AdaptLog {
  final List<AdaptLogInput> inputs;
  final List<AdaptLogOutput> outputs;

  /// Chamado a cada falha de adapter. O padrão escreve no console pela zona
  /// raiz, sem passar por interceptadores de `print`.
  final AdaptLogErrorHandler onError;

  late final AdaptLogController controller = AdaptLogController(this);

  AdaptLogState _state = AdaptLogState.created;
  Future<void>? _transition;

  AdaptLog({
    required List<AdaptLogInput> inputs,
    required List<AdaptLogOutput> outputs,
    AdaptLogErrorHandler? onError,
  })  : inputs = List<AdaptLogInput>.unmodifiable(inputs),
        outputs = List<AdaptLogOutput>.unmodifiable(outputs),
        onError = onError ?? defaultErrorHandler;

  AdaptLogState get state => _state;

  bool get isReady => _state == AdaptLogState.ready;

  /// Inicializa outputs e depois inputs. Idempotente. Uma falha em um adapter
  /// é reportada em [onError] e os demais seguem sendo inicializados.
  Future<void> initialize() {
    switch (_state) {
      case AdaptLogState.ready:
        return Future<void>.value();
      case AdaptLogState.initializing:
        return _transition!;
      case AdaptLogState.shuttingDown:
        return _transition!.then((_) => initialize());
      case AdaptLogState.created:
      case AdaptLogState.shutDown:
        _state = AdaptLogState.initializing;
        return _transition = _initialize();
    }
  }

  /// Aguarda as entries pendentes, encerra inputs e depois outputs, na ordem
  /// inversa de [initialize]. Idempotente. Entries logadas a partir daqui
  /// são descartadas.
  Future<void> shutdown() {
    switch (_state) {
      case AdaptLogState.created:
      case AdaptLogState.shutDown:
        return Future<void>.value();
      case AdaptLogState.shuttingDown:
        return _transition!;
      case AdaptLogState.initializing:
        return _transition!.then((_) => shutdown());
      case AdaptLogState.ready:
        _state = AdaptLogState.shuttingDown;
        return _transition = _shutdown();
    }
  }

  /// Completa quando todas as entries já logadas foram processadas.
  Future<void> flush() => controller.flush();

  /// Encaminha uma falha de adapter a [onError], protegendo o pipeline caso o
  /// handler também lance.
  void reportError(Object error, StackTrace stackTrace, AdaptLogAdapter adapter) {
    try {
      onError(error, stackTrace, adapter);
    } catch (_) {
      // Um handler defeituoso não pode derrubar o pipeline.
    }
  }

  static void defaultErrorHandler(
    Object error,
    StackTrace stackTrace,
    AdaptLogAdapter adapter,
  ) {
    Zone.root.print('[adapt_log] ${adapter.runtimeType} falhou: $error\n$stackTrace');
  }

  Future<void> _initialize() async {
    for (final output in outputs) {
      await _guard(output, () => output.initialize(controller));
    }
    for (final input in inputs) {
      await _guard(input, () => input.initialize(controller));
    }
    _state = AdaptLogState.ready;
  }

  Future<void> _shutdown() async {
    await controller.flush();
    for (final input in inputs.reversed) {
      await _guard(input, input.shutdown);
    }
    for (final output in outputs.reversed) {
      await _guard(output, output.shutdown);
    }
    _state = AdaptLogState.shutDown;
  }

  Future<void> _guard(AdaptLogAdapter adapter, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      reportError(error, stackTrace, adapter);
    }
  }
}
