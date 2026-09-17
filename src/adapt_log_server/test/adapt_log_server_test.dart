import 'dart:convert';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';
import 'package:adapt_log_server/adapt_log_server.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  late AdaptLogServer server;
  late Uri base;

  setUp(() async {
    server = AdaptLogServer(
      port: 0,
      dbPath: ':memory:',
      apiKeys: {'k-demo': 'demo', 'k-other': 'other'},
    );
    await server.start();
    base = server.url!;
  });

  tearDown(() => server.stop());

  Map<String, String> auth(String key) => {
        'authorization': 'Bearer $key',
        'content-type': 'application/json',
      };

  LogBatch batch(List<AdaptLogEntry> entries, {String sessionId = 's1'}) {
    return LogBatch(
      session: SessionInfo(id: sessionId, startedAt: DateTime.utc(2026, 9, 15), metadata: {'app.name': 'Demo'}),
      entries: entries,
    );
  }

  Future<http.Response> post(LogBatch batch, {String key = 'k-demo'}) {
    return http.post(base.resolve('/v1/logs'), headers: auth(key), body: jsonEncode(batch.toJson()));
  }

  Future<Map<String, dynamic>> getJson(String path, {String key = 'k-demo'}) async {
    final response = await http.get(base.resolve(path), headers: auth(key));
    expect(response.statusCode, 200, reason: response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<String> messagesOf(Map<String, dynamic> body) {
    return [for (final entry in body['entries'] as List) entry['message'] as String];
  }

  test('health e painel não exigem chave', () async {
    final health = await http.get(base.resolve('/health'));
    expect(health.statusCode, 200);
    expect(jsonDecode(health.body)['status'], 'ok');

    final panel = await http.get(base);
    expect(panel.statusCode, 200);
    expect(panel.headers['content-type'], contains('text/html'));
    expect(panel.body, contains('Prints antes do erro'));
    expect(panel.body, contains('Tela no momento do erro'));
  });

  test('POST /v1/logs exige chave válida', () async {
    final noKey = await http.post(base.resolve('/v1/logs'), headers: {'content-type': 'application/json'}, body: '{}');
    expect(noKey.statusCode, 401);

    final badKey = await post(batch([]), key: 'errada');
    expect(badKey.statusCode, 403);
  });

  test('POST /v1/logs rejeita corpo inválido com 400', () async {
    final wrongVersion = await http.post(base.resolve('/v1/logs'), headers: auth('k-demo'), body: '{"protocolVersion": 99}');
    expect(wrongVersion.statusCode, 400);
    expect(jsonDecode(wrongVersion.body)['error'], contains('lote inválido'));

    final notJson = await http.post(base.resolve('/v1/logs'), headers: auth('k-demo'), body: 'xx');
    expect(notJson.statusCode, 400);
  });

  test('grava o lote, deduplica reenvio e devolve o erro com prints, stack e sessão', () async {
    final error = AdaptLogEntry(
      message: 'Falha no checkout',
      level: AdaptLogLevel.error,
      error: StateError('estado ruim'),
      stackTrace: StackTrace.current,
      metadata: {'recentPrints': ['abrindo tela de pagamento', 'tocou em pagar']},
    );
    final info = AdaptLogEntry(message: 'App iniciado', level: AdaptLogLevel.info);
    final lote = batch([info, error]);

    final first = await post(lote);
    expect(first.statusCode, 202, reason: first.body);
    expect(jsonDecode(first.body), {'accepted': 2, 'stored': 2});
    final again = await post(lote);
    expect(jsonDecode(again.body), {'accepted': 2, 'stored': 0});

    final list = await getJson('/v1/logs');
    expect(messagesOf(list), ['Falha no checkout', 'App iniciado']);
    final stored = (list['entries'] as List).first as Map<String, dynamic>;
    expect(stored['id'], error.id);
    expect(stored['sessionId'], 's1');
    expect(stored['error'], 'Bad state: estado ruim');
    expect(stored['errorType'], 'StateError');
    expect(stored['stackTrace'], error.stackTrace.toString());
    expect(stored['metadata']['recentPrints'], ['abrindo tela de pagamento', 'tocou em pagar']);
    expect(stored['receivedAt'], isA<String>());
    expect(stored['seq'], isA<int>());

    final one = await getJson('/v1/logs/${error.id}');
    expect(one['message'], 'Falha no checkout');
    final missing = await http.get(base.resolve('/v1/logs/nao-existe'), headers: auth('k-demo'));
    expect(missing.statusCode, 404);
  });

  test('filtra por nível, sessão e busca, e pagina por before', () async {
    await post(batch([for (var i = 1; i <= 3; i++) AdaptLogEntry(message: 'info $i', level: AdaptLogLevel.info)], sessionId: 'sA'));
    await post(batch([AdaptLogEntry(message: 'erro X', level: AdaptLogLevel.error)], sessionId: 'sB'));

    expect(messagesOf(await getJson('/v1/logs?level=error')), ['erro X']);
    expect(messagesOf(await getJson('/v1/logs?session=sA')), ['info 3', 'info 2', 'info 1']);
    expect(messagesOf(await getJson('/v1/logs?search=INFO%202')), ['info 2']);

    final page1 = await getJson('/v1/logs?limit=2');
    expect(messagesOf(page1), ['erro X', 'info 3']);
    final page2 = await getJson('/v1/logs?limit=2&before=${page1['nextBefore']}');
    expect(messagesOf(page2), ['info 2', 'info 1']);

    final bad = await http.get(base.resolve('/v1/logs?level=nope'), headers: auth('k-demo'));
    expect(bad.statusCode, 400);
  });

  test('cada chave enxerga só o próprio projeto', () async {
    await post(batch([AdaptLogEntry(message: 'do demo', level: AdaptLogLevel.info)]));
    await post(batch([AdaptLogEntry(message: 'do other', level: AdaptLogLevel.info)]), key: 'k-other');

    expect(messagesOf(await getJson('/v1/logs')), ['do demo']);
    expect(messagesOf(await getJson('/v1/logs', key: 'k-other')), ['do other']);
  });

  test('sessões agregam contagens e metadata', () async {
    await post(batch([
      AdaptLogEntry(message: 'a', level: AdaptLogLevel.info),
      AdaptLogEntry(message: 'b', level: AdaptLogLevel.error),
    ]));
    await post(batch([AdaptLogEntry(message: 'c', level: AdaptLogLevel.error)]));

    final sessions = (await getJson('/v1/sessions'))['sessions'] as List;
    final session = sessions.single as Map<String, dynamic>;
    expect(session['id'], 's1');
    expect(session['entryCount'], 3);
    expect(session['errorCount'], 2);
    expect(session['metadata'], {'app.name': 'Demo'});
  });

  test('WebSocket /v1/stream envia hello e cada entry nova do projeto', () async {
    final wsUrl = base.replace(scheme: 'ws', path: '/v1/stream', queryParameters: {'key': 'k-demo'});
    final channel = IOWebSocketChannel.connect(wsUrl);
    final messages = channel.stream.map((m) => jsonDecode(m as String) as Map<String, dynamic>).asBroadcastStream();

    final hello = await messages.first.timeout(const Duration(seconds: 3));
    expect(hello['type'], 'hello');
    expect(hello['project'], 'demo');

    final next = messages.first;
    await post(batch([AdaptLogEntry(message: 'de outro projeto', level: AdaptLogLevel.error)]), key: 'k-other');
    final error = AdaptLogEntry(message: 'ao vivo', level: AdaptLogLevel.error);
    await post(batch([error]));

    final event = LogStreamEvent.fromJson(await next.timeout(const Duration(seconds: 3)));
    expect(event.project, 'demo');
    expect(event.sessionId, 's1');
    expect(event.entry.id, error.id);
    await channel.sink.close();
  });

  const onePixelPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

  test('screenshot ligada ao erro é extraída da metadata, marcada no erro e servida como imagem', () async {
    final error = AdaptLogEntry(message: 'boom', level: AdaptLogLevel.error);
    final shot = AdaptLogEntry(
      message: 'Screenshot: boom',
      level: AdaptLogLevel.info,
      metadata: {
        'isScreenshot': true,
        'screenshotFor': error.id,
        'screenshotFormat': 'png',
        'screenshotWidth': 1,
        'screenshotHeight': 1,
        'screenshot': onePixelPng,
      },
    );

    final response = await post(batch([error, shot]));
    expect(response.statusCode, 202, reason: response.body);

    final entries = (await getJson('/v1/logs'))['entries'] as List;
    final storedShot = entries.first as Map<String, dynamic>;
    final storedError = entries.last as Map<String, dynamic>;
    expect(storedShot['id'], shot.id);
    expect((storedShot['metadata'] as Map).containsKey('screenshot'), isFalse);
    expect(storedShot['metadata']['hasScreenshot'], isTrue);
    expect(storedShot['metadata']['screenshotFor'], error.id);
    expect(storedError['metadata']['hasScreenshot'], isTrue);

    for (final id in [error.id, shot.id]) {
      final image = await http.get(base.resolve('/v1/logs/$id/screenshot'), headers: auth('k-demo'));
      expect(image.statusCode, 200, reason: 'id $id');
      expect(image.headers['content-type'], 'image/png');
      expect(image.bodyBytes, base64Decode(onePixelPng));
    }
    final viaQuery = await http.get(base.resolve('/v1/logs/${error.id}/screenshot?key=k-demo'));
    expect(viaQuery.statusCode, 200);
    final missing = await http.get(base.resolve('/v1/logs/nao-existe/screenshot'), headers: auth('k-demo'));
    expect(missing.statusCode, 404);
    final otherProject = await http.get(base.resolve('/v1/logs/${error.id}/screenshot'), headers: auth('k-other'));
    expect(otherProject.statusCode, 404);
  });

  test('evento de stream da screenshot não carrega o base64', () async {
    final wsUrl = base.replace(scheme: 'ws', path: '/v1/stream', queryParameters: {'key': 'k-demo'});
    final channel = IOWebSocketChannel.connect(wsUrl);
    final messages = channel.stream.map((m) => jsonDecode(m as String) as Map<String, dynamic>).asBroadcastStream();
    await messages.first.timeout(const Duration(seconds: 3));

    final collected = <Map<String, dynamic>>[];
    final done = messages.take(2).forEach(collected.add);
    final error = AdaptLogEntry(message: 'boom', level: AdaptLogLevel.error);
    final shot = AdaptLogEntry(
      message: 'Screenshot: boom',
      level: AdaptLogLevel.info,
      metadata: {'isScreenshot': true, 'screenshotFor': error.id, 'screenshot': onePixelPng},
    );
    await post(batch([error, shot]));
    await done.timeout(const Duration(seconds: 3));

    final shotEvent = LogStreamEvent.fromJson(collected.last);
    expect(shotEvent.entry.id, shot.id);
    expect(shotEvent.entry.metadata.containsKey('screenshot'), isFalse);
    expect(shotEvent.entry.metadata['hasScreenshot'], isTrue);
    await channel.sink.close();
  });

  test('stream sem chave ou com chave inválida é recusado antes do upgrade', () async {
    final noKey = await http.get(base.resolve('/v1/stream'));
    expect(noKey.statusCode, 401);

    final badKey = await http.get(base.resolve('/v1/stream?key=errada'));
    expect(badKey.statusCode, 403);
  });
}
