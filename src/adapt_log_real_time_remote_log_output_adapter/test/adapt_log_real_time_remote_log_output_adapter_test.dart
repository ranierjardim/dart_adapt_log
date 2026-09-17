import 'dart:convert';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_real_time_remote_log_output_adapter/adapt_log_real_time_remote_log_output_adapter.dart';
import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class Emitter extends AdaptLogInput {
  Future<void> emit(String message, [AdaptLogLevel level = AdaptLogLevel.info]) {
    return controller.log(AdaptLogEntry(message: message, level: level));
  }
}

Future<void> waitUntil(bool Function() condition, {Duration timeout = const Duration(seconds: 3)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condição não satisfeita em $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Emitter emitter;
  late List<Object> errors;
  late List<http.Request> requests;
  late AdaptLog adaptLog;
  late RealTimeRemoteLogOutputAdapter remote;

  Future<void> start(
    Future<http.Response> Function(http.Request request) handler, {
    int batchSize = 50,
    int maxBatchBytes = 4 * 1024 * 1024,
    Duration flushInterval = const Duration(milliseconds: 20),
    int maxBufferedEntries = 5000,
    AdaptLogLevel minLevel = AdaptLogLevel.debug,
    Duration initialBackoff = const Duration(milliseconds: 10),
    Duration maxBackoff = const Duration(milliseconds: 20),
  }) async {
    emitter = Emitter();
    errors = [];
    requests = [];
    remote = RealTimeRemoteLogOutputAdapter(
      serverUrl: 'https://logs.example.com/base/',
      apiKey: 'chave-secreta',
      batchSize: batchSize,
      maxBatchBytes: maxBatchBytes,
      flushInterval: flushInterval,
      maxBufferedEntries: maxBufferedEntries,
      minLevel: minLevel,
      initialBackoff: initialBackoff,
      maxBackoff: maxBackoff,
      requestTimeout: const Duration(seconds: 1),
      sessionMetadata: {'app.version': '1.2.3'},
      client: MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
    );
    adaptLog = AdaptLog(
      inputs: [emitter],
      outputs: [remote],
      onError: (error, _, __) => errors.add(error),
    );
    await adaptLog.initialize();
  }

  Future<http.Response> ok(http.Request request) async => http.Response('{"accepted":1}', 200);

  Map<String, dynamic> bodyOf(http.Request request) => jsonDecode(request.body) as Map<String, dynamic>;

  tearDown(() => adaptLog.shutdown());

  test('envia lote autenticado com sessão e entries após flushInterval', () async {
    await start(ok);

    await emitter.emit('oi');
    await waitUntil(() => requests.length == 1);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.toString(), 'https://logs.example.com/base/v1/logs');
    expect(request.headers['authorization'], 'Bearer chave-secreta');
    expect(request.headers[AdaptLogProtocol.versionHeader], '1');
    expect(request.headers['content-type'], startsWith('application/json'));

    final batch = LogBatch.fromJson(bodyOf(request));
    expect(batch.session.id, remote.session!.id);
    expect(batch.session.metadata, {'app.version': '1.2.3'});
    expect(batch.entries.single.message, 'oi');
    expect(remote.sentEntries, 1);
    expect(remote.pendingEntries, 0);
    expect(errors, isEmpty);
  });

  test('lote cheio dispara envio imediato e mantém a ordem', () async {
    await start(ok, batchSize: 3, flushInterval: const Duration(seconds: 10));

    await emitter.emit('1');
    await emitter.emit('2');
    await emitter.emit('3');
    await waitUntil(() => requests.length == 1);

    expect(LogBatch.fromJson(bodyOf(requests.single)).entries.map((e) => e.message), ['1', '2', '3']);
  });

  test('maxBatchBytes divide o lote por tamanho e mantém a ordem', () async {
    await start(ok, flushInterval: const Duration(seconds: 10), maxBatchBytes: 700);
    final big = 'x' * 400;

    await emitter.emit('1 $big');
    await emitter.emit('2 $big');
    await emitter.emit('3 $big');
    await remote.flush();

    expect(requests.length, greaterThan(1));
    final messages = [
      for (final request in requests)
        for (final entry in LogBatch.fromJson(bodyOf(request)).entries) entry.message.substring(0, 1),
    ];
    expect(messages, ['1', '2', '3']);
    expect(remote.sentEntries, 3);
  });

  test('falha 500 entra em backoff, reenvia e reporta só a primeira falha da sequência', () async {
    var calls = 0;
    await start((request) async {
      calls++;
      return calls < 3 ? http.Response('indisponível', 500) : http.Response('', 200);
    });

    await emitter.emit('oi');
    await waitUntil(() => requests.length == 2);
    expect(remote.state, isA<RemoteLogBackingOff>());
    await waitUntil(() => remote.sentEntries == 1);

    expect(requests, hasLength(3));
    expect(errors.single, isA<RemoteLogServerException>());
    expect(remote.state, isA<RemoteLogIdle>());
    expect(remote.pendingEntries, 0);
  });

  test('falha de rede vai para onError e entra em backoff', () async {
    await start((request) async => throw http.ClientException('sem rede'));

    await emitter.emit('oi');
    await waitUntil(() => errors.isNotEmpty);

    expect(errors.single, isA<http.ClientException>());
    expect(remote.state, isA<RemoteLogBackingOff>());
    expect(remote.pendingEntries, 1);
  });

  test('resposta 4xx descarta o lote e reporta', () async {
    await start((request) async => http.Response('chave inválida', 401));

    await emitter.emit('oi');
    await waitUntil(() => errors.isNotEmpty);

    expect(errors.single, isA<RemoteLogRejectedException>());
    expect(remote.droppedEntries, 1);
    expect(remote.pendingEntries, 0);
    expect(remote.state, isA<RemoteLogIdle>());
  });

  test('minLevel filtra entries abaixo do nível', () async {
    await start(ok, minLevel: AdaptLogLevel.warning);

    await emitter.emit('debug', AdaptLogLevel.debug);
    await emitter.emit('info');
    await emitter.emit('erro', AdaptLogLevel.error);
    await waitUntil(() => requests.length == 1);

    expect(LogBatch.fromJson(bodyOf(requests.single)).entries.map((e) => e.message), ['erro']);
  });

  test('fila cheia descarta as entries mais antigas', () async {
    await start(ok, maxBufferedEntries: 2, flushInterval: const Duration(seconds: 10));

    await emitter.emit('a');
    await emitter.emit('b');
    await emitter.emit('c');

    expect(remote.pendingEntries, 2);
    expect(remote.droppedEntries, 1);
    await remote.flush();
    expect(LogBatch.fromJson(bodyOf(requests.single)).entries.map((e) => e.message), ['b', 'c']);
  });

  test('shutdown envia o que restou na fila', () async {
    await start(ok, flushInterval: const Duration(seconds: 10));

    await emitter.emit('última');
    await adaptLog.shutdown();

    expect(requests, hasLength(1));
    expect(remote.state, isA<RemoteLogStopped>());
    expect(remote.sentEntries, 1);
  });
}
