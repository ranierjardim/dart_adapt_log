import 'dart:async';
import 'dart:collection';

import 'adapt_log.dart';
import 'adapt_log_adapter.dart';
import 'adapt_log_entry.dart';
import 'adapt_log_output.dart';

/// Ponto de entrada das entries. Recebido por cada adapter em `initialize()`.
///
/// Garantias de [log]:
/// - nunca lança por falha de adapter: exceções de `enrichEntry` e de
///   `onNewLog` são isoladas e reportadas em `AdaptLog.onError`;
/// - cada output recebe as entries na ordem em que foram logadas, e outputs
///   diferentes não bloqueiam uns aos outros;
/// - uma entry logada de dentro de `enrichEntry` entra na fila e é despachada
///   depois da entry atual;
/// - uma entry logada de dentro de `onNewLog` de um output, direta ou
///   indiretamente, é descartada para evitar recursão infinita;
/// - antes de `AdaptLog.initialize()` lança [StateError]; durante ou depois de
///   `AdaptLog.shutdown()` a entry é descartada silenciosamente.
class AdaptLogController {
  static final Object _dispatchingOutput = Object();

  final AdaptLog _adaptLog;
  final Queue<_QueuedEntry> _queue = Queue<_QueuedEntry>();
  final Map<AdaptLogOutput, Future<void>> _tails = {};
  bool _draining = false;

  AdaptLogController(this._adaptLog);

  /// Enfileira [entry] e retorna um `Future` que completa quando todos os
  /// outputs a processaram. Aguardá-lo é opcional.
  Future<void> log(AdaptLogEntry entry) {
    if (Zone.current[_dispatchingOutput] != null) {
      // Emitida de dentro de um output: descartada.
      return Future<void>.value();
    }
    switch (_adaptLog.state) {
      case AdaptLogState.created:
        throw StateError(
          'AdaptLog ainda não foi inicializado. Aguarde AdaptLog.initialize() '
          'antes de logar.',
        );
      case AdaptLogState.shuttingDown:
      case AdaptLogState.shutDown:
        return Future<void>.value();
      case AdaptLogState.initializing:
      case AdaptLogState.ready:
        break;
    }
    final queued = _QueuedEntry(entry);
    _queue.add(queued);
    _drain();
    return queued.done.future;
  }

  /// Completa quando todas as entries já logadas foram processadas por todos
  /// os outputs.
  Future<void> flush() {
    return Future.wait(_tails.values.toList()).then((_) {});
  }

  /// Reporta uma falha de [adapter] em `AdaptLog.onError`. Para adapters que
  /// fazem trabalho assíncrono fora do pipeline (o core já cobre
  /// `initialize`, `enrichEntry`, `onNewLog` e `shutdown`).
  void reportError(Object error, StackTrace stackTrace, AdaptLogAdapter adapter) {
    _adaptLog.reportError(error, stackTrace, adapter);
  }

  void _drain() {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        _process(_queue.removeFirst());
      }
    } finally {
      _draining = false;
    }
  }

  void _process(_QueuedEntry queued) {
    var entry = queued.entry;
    for (final input in _adaptLog.inputs) {
      try {
        entry = input.enrichEntry(entry);
      } catch (error, stackTrace) {
        _adaptLog.reportError(error, stackTrace, input);
      }
    }
    final pending = <Future<void>>[];
    for (final output in _adaptLog.outputs) {
      final tail = _tails[output] ?? Future<void>.value();
      final next = tail.then((_) => _dispatch(output, entry));
      _tails[output] = next;
      pending.add(next);
    }
    queued.done.complete(Future.wait(pending).then((_) {}));
  }

  Future<void> _dispatch(AdaptLogOutput output, AdaptLogEntry entry) {
    // Tudo que pode falhar roda numa zona guardada própria do output. Erros
    // não cruzam a fronteira de uma error zone, então o sinal de conclusão sai
    // por um Completer de valor, nunca por um Future que possa falhar.
    final done = Completer<void>();
    unawaited(runZonedGuarded(
      () async {
        try {
          await output.onNewLog(entry);
        } catch (error, stackTrace) {
          _adaptLog.reportError(error, stackTrace, output);
        } finally {
          done.complete();
        }
      },
      (error, stackTrace) => _adaptLog.reportError(error, stackTrace, output),
      zoneValues: {_dispatchingOutput: output},
    ));
    return done.future;
  }
}

class _QueuedEntry {
  final AdaptLogEntry entry;
  final Completer<void> done = Completer<void>();

  _QueuedEntry(this.entry);
}
