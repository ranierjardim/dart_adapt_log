import 'dart:async';

import 'package:adapt_log/adapt_log.dart';
import 'package:test/test.dart';

AdaptLogEntry _entry(String message, [AdaptLogLevel level = AdaptLogLevel.info]) {
  return AdaptLogEntry(message: message, level: level);
}

class Emitter extends AdaptLogInput {
  Future<void> emit(String message, [AdaptLogLevel level = AdaptLogLevel.info]) {
    return controller.log(_entry(message, level));
  }
}

class Enricher extends AdaptLogInput {
  final String key;
  Enricher(this.key);

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    final order = [...?(entry.metadata['order'] as List<String>?), key];
    return entry.copyWith(metadata: {...entry.metadata, 'order': order});
  }
}

class ThrowingEnricher extends AdaptLogInput {
  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) => throw StateError('enricher quebrou');
}

class NestedEnricher extends AdaptLogInput {
  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    if (entry.level == AdaptLogLevel.error) {
      controller.log(_entry('report'));
    }
    return entry;
  }
}

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  List<String> get messages => entries.map((e) => e.message).toList();

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

class Throwing extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => throw StateError('quebrou');
}

class SyncThrowing extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) => throw StateError('quebrou sync');
}

class AsyncFailing extends AdaptLogOutput {
  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    // Erro em future nunca aguardado: só a zona do despacho o captura.
    Future<void>.delayed(Duration.zero, () => throw StateError('assíncrono'));
  }
}

class Reentrant extends AdaptLogOutput {
  int calls = 0;

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    calls++;
    await controller.log(_entry('nested'));
  }
}

class Slow extends AdaptLogOutput {
  final events = <String>[];

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    final ms = entry.level == AdaptLogLevel.error ? 30 : 1;
    await Future<void>.delayed(Duration(milliseconds: ms));
    events.add(entry.message);
  }

  @override
  Future<void> shutdown() async {
    await super.shutdown();
    events.add('shutdown');
  }
}

class Recorder {
  final events = <String>[];
}

class RecInput extends AdaptLogInput {
  final Recorder recorder;
  final String name;
  RecInput(this.recorder, this.name);

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    recorder.events.add('init $name');
  }

  @override
  Future<void> shutdown() async {
    await super.shutdown();
    recorder.events.add('shutdown $name');
  }
}

class RecOutput extends AdaptLogOutput {
  final Recorder recorder;
  final String name;
  RecOutput(this.recorder, this.name);

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    recorder.events.add('init $name');
  }

  @override
  Future<void> shutdown() async {
    await super.shutdown();
    recorder.events.add('shutdown $name');
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {}
}

class FailingInit extends AdaptLogOutput {
  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    throw StateError('init quebrou');
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {}
}

void main() {
  group('pipeline', () {
    test('entrega a entry a todos os outputs, enriquecida na ordem dos inputs', () async {
      final emitter = Emitter();
      final a = Collector();
      final b = Collector();
      final log = AdaptLog(
        inputs: [Enricher('x'), emitter, Enricher('y')],
        outputs: [a, b],
      );
      await log.initialize();

      await emitter.emit('oi');

      expect(a.messages, ['oi']);
      expect(b.messages, ['oi']);
      expect(b.entries.single.metadata['order'], ['x', 'y']);
    });

    test('output que lança não afeta os demais nem o chamador; onError recebe o adapter', () async {
      final errors = <Object>[];
      final adapters = <AdaptLogAdapter>[];
      final emitter = Emitter();
      final bad = Throwing();
      final badSync = SyncThrowing();
      final ok = Collector();
      final log = AdaptLog(
        inputs: [emitter],
        outputs: [bad, badSync, ok],
        onError: (error, _, adapter) {
          errors.add(error);
          adapters.add(adapter);
        },
      );
      await log.initialize();

      await emitter.emit('oi');

      expect(ok.messages, ['oi']);
      expect(errors, hasLength(2));
      expect(adapters, unorderedEquals([bad, badSync]));
    });

    test('enricher que lança é reportado e a entry segue sem o enriquecimento', () async {
      final errors = <Object>[];
      final emitter = Emitter();
      final out = Collector();
      final log = AdaptLog(
        inputs: [emitter, ThrowingEnricher(), Enricher('y')],
        outputs: [out],
        onError: (error, _, __) => errors.add(error),
      );
      await log.initialize();

      await emitter.emit('oi');

      expect(out.entries.single.metadata['order'], ['y']);
      expect(errors.single, isA<StateError>());
    });

    test('erro assíncrono não tratado dentro de um output vai para onError', () async {
      final errors = <Object>[];
      final reported = Completer<void>();
      final emitter = Emitter();
      final log = AdaptLog(
        inputs: [emitter],
        outputs: [AsyncFailing()],
        onError: (error, _, __) {
          errors.add(error);
          if (!reported.isCompleted) reported.complete();
        },
      );
      await log.initialize();

      await emitter.emit('oi');
      await reported.future.timeout(const Duration(seconds: 2));

      expect(errors.single, isA<StateError>());
    });

    test('log() re-entrante de dentro de um output é descartado, sem recursão', () async {
      final emitter = Emitter();
      final reentrant = Reentrant();
      final out = Collector();
      final log = AdaptLog(inputs: [emitter], outputs: [reentrant, out]);
      await log.initialize();

      await emitter.emit('oi');
      await log.flush();

      expect(reentrant.calls, 1);
      expect(out.messages, ['oi']);
    });

    test('log() disparado de dentro de enrichEntry chega depois da entry original', () async {
      final emitter = Emitter();
      final out = Collector();
      final log = AdaptLog(inputs: [emitter, NestedEnricher()], outputs: [out]);
      await log.initialize();

      await emitter.emit('boom', AdaptLogLevel.error);
      await log.flush();

      expect(out.messages, ['boom', 'report']);
    });

    test('ordem por output é preservada com outputs assíncronos', () async {
      final emitter = Emitter();
      final slow = Slow();
      final log = AdaptLog(inputs: [emitter], outputs: [slow]);
      await log.initialize();

      final first = emitter.emit('primeiro', AdaptLogLevel.error);
      final second = emitter.emit('segundo');
      await Future.wait([first, second]);

      expect(slow.events, ['primeiro', 'segundo']);
    });

    test('flush aguarda todos os outputs', () async {
      final emitter = Emitter();
      final slow = Slow();
      final log = AdaptLog(inputs: [emitter], outputs: [slow]);
      await log.initialize();

      unawaited(emitter.emit('a'));
      unawaited(emitter.emit('b'));
      await log.flush();

      expect(slow.events, ['a', 'b']);
    });

    test('metadata da entry é imutável', () {
      final entry = AdaptLogEntry(
        message: 'x',
        level: AdaptLogLevel.info,
        metadata: {'a': 1},
      );
      expect(() => entry.metadata['b'] = 2, throwsUnsupportedError);
      expect(entry.copyWith(metadata: {'b': 2}).metadata, {'b': 2});
    });
  });

  group('ciclo de vida', () {
    test('input usado antes de initialize lança StateError claro', () {
      final emitter = Emitter();
      expect(
        () => emitter.emit('cedo'),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Emitter'))),
      );
    });

    test('controller.log antes de initialize lança StateError', () {
      final log = AdaptLog(inputs: const [], outputs: const []);
      expect(() => log.controller.log(_entry('cedo')), throwsA(isA<StateError>()));
    });

    test('log após shutdown é descartado sem lançar', () async {
      final emitter = Emitter();
      final out = Collector();
      final log = AdaptLog(inputs: [emitter], outputs: [out]);
      await log.initialize();
      await emitter.emit('antes');
      await log.shutdown();

      await emitter.emit('depois');

      expect(out.messages, ['antes']);
      expect(log.state, AdaptLogState.shutDown);
    });

    test('shutdown aguarda entries pendentes antes de encerrar outputs', () async {
      final emitter = Emitter();
      final slow = Slow();
      final log = AdaptLog(inputs: [emitter], outputs: [slow]);
      await log.initialize();

      unawaited(emitter.emit('pendente', AdaptLogLevel.error));
      await log.shutdown();

      expect(slow.events, ['pendente', 'shutdown']);
    });

    test('inicializa outputs antes dos inputs e encerra na ordem inversa', () async {
      final recorder = Recorder();
      final log = AdaptLog(
        inputs: [RecInput(recorder, 'a'), RecInput(recorder, 'b')],
        outputs: [RecOutput(recorder, 'x'), RecOutput(recorder, 'y')],
      );

      await log.initialize();
      await log.shutdown();

      expect(recorder.events, [
        'init x', 'init y', 'init a', 'init b',
        'shutdown b', 'shutdown a', 'shutdown y', 'shutdown x',
      ]);
    });

    test('falha em initialize de um adapter é reportada e os demais inicializam', () async {
      final errors = <Object>[];
      final emitter = Emitter();
      final out = Collector();
      final log = AdaptLog(
        inputs: [emitter],
        outputs: [FailingInit(), out],
        onError: (error, _, __) => errors.add(error),
      );

      await log.initialize();
      await emitter.emit('oi');

      expect(log.isReady, isTrue);
      expect(errors.single, isA<StateError>());
      expect(out.messages, ['oi']);
    });

    test('initialize e shutdown são idempotentes, inclusive concorrentes', () async {
      final recorder = Recorder();
      final log = AdaptLog(inputs: [RecInput(recorder, 'a')], outputs: const []);

      await Future.wait([log.initialize(), log.initialize()]);
      await log.initialize();
      await Future.wait([log.shutdown(), log.shutdown()]);
      await log.shutdown();

      expect(recorder.events, ['init a', 'shutdown a']);
    });

    test('pode ser reinicializado depois do shutdown', () async {
      final emitter = Emitter();
      final out = Collector();
      final log = AdaptLog(inputs: [emitter], outputs: [out]);
      await log.initialize();
      await log.shutdown();

      await log.initialize();
      await emitter.emit('de novo');

      expect(out.messages, ['de novo']);
    });

    test('onError que lança não derruba o pipeline', () async {
      final emitter = Emitter();
      final out = Collector();
      final log = AdaptLog(
        inputs: [emitter],
        outputs: [Throwing(), out],
        onError: (_, __, ___) => throw StateError('handler quebrou'),
      );
      await log.initialize();

      await emitter.emit('oi');

      expect(out.messages, ['oi']);
    });
  });

  group('AdaptLogEntry', () {
    test('gera ids únicos', () {
      final ids = {for (var i = 0; i < 2000; i++) AdaptLogEntry.generateId()};
      expect(ids, hasLength(2000));
    });

    test('toJson/fromJson preservam todos os campos, com timestamp em UTC', () {
      final stack = StackTrace.current;
      final entry = AdaptLogEntry(
        message: 'falhou',
        level: AdaptLogLevel.error,
        timestamp: DateTime(2026, 9, 15, 12, 30),
        error: StateError('estado ruim'),
        stackTrace: stack,
        metadata: {'userId': 7, 'tags': ['a', 'b'], 'nested': {'x': 1}},
      );

      final json = entry.toJson();
      expect(json['id'], entry.id);
      expect(json['level'], 'error');
      expect(json['timestamp'], DateTime(2026, 9, 15, 12, 30).toUtc().toIso8601String());
      expect(json['error'], 'Bad state: estado ruim');
      expect(json['errorType'], 'StateError');
      expect(json['stackTrace'], stack.toString());

      final back = AdaptLogEntry.fromJson(json);
      expect(back.id, entry.id);
      expect(back.message, 'falhou');
      expect(back.level, AdaptLogLevel.error);
      expect(back.timestamp.toUtc(), entry.timestamp.toUtc());
      expect(back.error.toString(), 'Bad state: estado ruim');
      expect(back.errorType, 'StateError');
      expect(back.stackTrace.toString(), stack.toString());
      expect(back.metadata, {'userId': 7, 'tags': ['a', 'b'], 'nested': {'x': 1}});
    });

    test('toJson converte metadata não serializável em texto', () {
      final when = DateTime.utc(2026, 1, 1);
      final entry = AdaptLogEntry(
        message: 'x',
        level: AdaptLogLevel.info,
        metadata: {'when': when, 'set': {1, 2}, 'map': {1: when}},
      );

      final metadata = entry.toJson()['metadata'] as Map<String, dynamic>;
      expect(metadata['when'], when.toString());
      expect(metadata['set'], [1, 2]);
      expect(metadata['map'], {'1': when.toString()});
    });

    test('entry sem error não emite as chaves de erro', () {
      final json = AdaptLogEntry(message: 'x', level: AdaptLogLevel.info).toJson();
      expect(json.containsKey('error'), isFalse);
      expect(json.containsKey('errorType'), isFalse);
      expect(json.containsKey('stackTrace'), isFalse);
    });
  });
}
