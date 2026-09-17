import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';
import 'package:http/http.dart' as http;

/// Estado do envio ao servidor.
sealed class RemoteLogState {
  const RemoteLogState();
}

/// Sem envio em andamento nem falha pendente.
class RemoteLogIdle extends RemoteLogState {
  const RemoteLogIdle();
}

/// Um lote está sendo enviado.
class RemoteLogSending extends RemoteLogState {
  const RemoteLogSending();
}

/// A última tentativa falhou; a próxima acontece em [until].
class RemoteLogBackingOff extends RemoteLogState {
  final int attempt;
  final DateTime until;
  final Object error;

  const RemoteLogBackingOff({required this.attempt, required this.until, required this.error});
}

/// Adapter encerrado; entries novas são descartadas.
class RemoteLogStopped extends RemoteLogState {
  const RemoteLogStopped();
}

/// O servidor recusou um lote com um erro do cliente (4xx). Reenviar não
/// resolve, então o lote foi descartado.
class RemoteLogRejectedException implements Exception {
  final int statusCode;
  final String body;

  const RemoteLogRejectedException(this.statusCode, this.body);

  @override
  String toString() => 'RemoteLogRejectedException($statusCode): $body';
}

/// O servidor respondeu com erro temporário (5xx, 408 ou 429); o lote será
/// reenviado.
class RemoteLogServerException implements Exception {
  final int statusCode;
  final String body;

  const RemoteLogServerException(this.statusCode, this.body);

  @override
  String toString() => 'RemoteLogServerException($statusCode): $body';
}

/// Transmite as entries ao adapt_log_server.
///
/// - Acumula entries e envia em lotes de até [batchSize] entries ou
///   [maxBatchBytes] de JSON a cada [flushInterval], ou imediatamente quando
///   o lote enche. Screenshots em base64 pesam; o limite em bytes evita
///   ultrapassar o que o servidor aceita por requisição.
/// - Falhas de rede e respostas 5xx/408/429 mantêm o lote na fila e reenviam
///   com backoff exponencial entre [initialBackoff] e [maxBackoff]. Respostas
///   4xx descartam o lote. A primeira falha de cada sequência e cada lote
///   descartado são reportados em `AdaptLog.onError`.
/// - A fila guarda no máximo [maxBufferedEntries]; acima disso as mais antigas
///   são descartadas e contadas em [droppedEntries].
/// - `shutdown()` tenta enviar o que restou antes de encerrar.
///
/// CLOSED SOURCE — disponível via assinatura.
class RealTimeRemoteLogOutputAdapter extends AdaptLogOutput {
  final Uri serverUrl;
  final String apiKey;

  /// Nível mínimo transmitido. Abaixo dele a entry é ignorada.
  final AdaptLogLevel minLevel;
  final int batchSize;

  /// Tamanho máximo do JSON de um lote. Uma entry maior que isso vai sozinha.
  final int maxBatchBytes;
  final Duration flushInterval;
  final int maxBufferedEntries;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final Duration requestTimeout;

  /// Informações fixas da sessão enviadas em todo lote (app, usuário...).
  final Map<String, dynamic> sessionMetadata;

  final http.Client? _injectedClient;
  http.Client? _client;
  SessionInfo? _session;
  final ListQueue<AdaptLogEntry> _queue = ListQueue<AdaptLogEntry>();
  Timer? _flushTimer;
  Timer? _retryTimer;
  Future<void>? _inFlight;
  int _attempt = 0;
  int _dropped = 0;
  int _sent = 0;
  RemoteLogState _state = const RemoteLogIdle();

  RealTimeRemoteLogOutputAdapter({
    required String serverUrl,
    required this.apiKey,
    this.minLevel = AdaptLogLevel.debug,
    this.batchSize = 50,
    this.maxBatchBytes = 4 * 1024 * 1024,
    this.flushInterval = const Duration(seconds: 2),
    this.maxBufferedEntries = 5000,
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 10),
    this.sessionMetadata = const {},
    http.Client? client,
  })  : assert(batchSize > 0),
        assert(maxBatchBytes > 0),
        assert(maxBufferedEntries > 0),
        serverUrl = Uri.parse(serverUrl),
        _injectedClient = client;

  /// Sessão atual, criada em [initialize].
  SessionInfo? get session => _session;

  RemoteLogState get state => _state;

  /// Entries aguardando envio.
  int get pendingEntries => _queue.length;

  /// Entries descartadas por fila cheia ou por lote recusado.
  int get droppedEntries => _dropped;

  /// Entries confirmadas pelo servidor.
  int get sentEntries => _sent;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    _client = _injectedClient ?? http.Client();
    _session = SessionInfo(
      id: AdaptLogEntry.generateId(),
      startedAt: DateTime.now(),
      metadata: sessionMetadata,
    );
    _attempt = 0;
    _state = const RemoteLogIdle();
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    if (_state is RemoteLogStopped) return;
    if (entry.level.index < minLevel.index) return;
    if (_queue.length >= maxBufferedEntries) {
      _queue.removeFirst();
      _dropped++;
    }
    _queue.addLast(entry);
    if (_state is RemoteLogBackingOff) return; // o timer de reenvio cuida.
    if (_queue.length >= batchSize) {
      _flushTimer?.cancel();
      _flushTimer = null;
      unawaited(flush());
    } else {
      _flushTimer ??= Timer(flushInterval, () {
        _flushTimer = null;
        unawaited(flush());
      });
    }
  }

  /// Envia tudo que está na fila, um lote por vez. Completa quando a fila
  /// esvazia ou quando uma tentativa falha; nesse caso o reenvio é agendado
  /// com backoff. Nunca lança.
  Future<void> flush() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    _retryTimer?.cancel();
    _retryTimer = null;
    final run = _drain().whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  @override
  Future<void> shutdown() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_queue.isNotEmpty) {
      try {
        await flush().timeout(requestTimeout + const Duration(seconds: 1));
      } on TimeoutException {
        // O que não deu pra enviar fica descartado com o encerramento.
      }
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _state = const RemoteLogStopped();
    if (_injectedClient == null) _client?.close();
    _client = null;
    await super.shutdown();
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty && _state is! RemoteLogStopped) {
      final batch = _takeBatch();
      final result = await _send(batch);
      switch (result) {
        case _SendResult.delivered:
          _removeFromQueue(batch.length);
          _sent += batch.length;
        case _SendResult.rejected:
          _removeFromQueue(batch.length);
          _dropped += batch.length;
        case _SendResult.retryLater:
          return;
      }
    }
  }

  /// Próximo lote: até [batchSize] entries ou [maxBatchBytes]; uma entry
  /// sozinha nunca é retida por tamanho.
  List<AdaptLogEntry> _takeBatch() {
    final batch = <AdaptLogEntry>[];
    var bytes = 0;
    for (final entry in _queue) {
      final size = utf8.encode(jsonEncode(entry.toJson())).length;
      if (batch.isNotEmpty && bytes + size > maxBatchBytes) break;
      batch.add(entry);
      bytes += size;
      if (batch.length >= batchSize) break;
    }
    return batch;
  }

  void _removeFromQueue(int count) {
    for (var i = 0; i < count && _queue.isNotEmpty; i++) {
      _queue.removeFirst();
    }
  }

  Future<_SendResult> _send(List<AdaptLogEntry> batch) async {
    final client = _client;
    final session = _session;
    if (client == null || session == null) return _SendResult.retryLater;
    _state = const RemoteLogSending();
    try {
      final response = await client
          .post(
            _endpoint(AdaptLogProtocol.logsPath),
            headers: {
              'content-type': 'application/json',
              AdaptLogProtocol.authorizationHeader: 'Bearer $apiKey',
              AdaptLogProtocol.versionHeader: '${AdaptLogProtocol.version}',
            },
            body: jsonEncode(LogBatch(session: session, entries: batch).toJson()),
          )
          .timeout(requestTimeout);
      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        _attempt = 0;
        _state = const RemoteLogIdle();
        return _SendResult.delivered;
      }
      if (status >= 400 && status < 500 && status != 408 && status != 429) {
        _attempt = 0;
        _state = const RemoteLogIdle();
        controller.reportError(
          RemoteLogRejectedException(status, response.body),
          StackTrace.current,
          this,
        );
        return _SendResult.rejected;
      }
      _scheduleRetry(RemoteLogServerException(status, response.body), StackTrace.current);
      return _SendResult.retryLater;
    } catch (error, stackTrace) {
      _scheduleRetry(error, stackTrace);
      return _SendResult.retryLater;
    }
  }

  void _scheduleRetry(Object error, StackTrace stackTrace) {
    if (_state is RemoteLogStopped) return;
    _attempt++;
    final factor = pow(2, min(_attempt - 1, 16)).toInt();
    final backoff = initialBackoff * factor > maxBackoff ? maxBackoff : initialBackoff * factor;
    _state = RemoteLogBackingOff(
      attempt: _attempt,
      until: DateTime.now().add(backoff),
      error: error,
    );
    if (_attempt == 1) {
      controller.reportError(error, stackTrace, this);
    }
    _retryTimer?.cancel();
    _retryTimer = Timer(backoff, () {
      _retryTimer = null;
      if (_state is RemoteLogStopped) return;
      _state = const RemoteLogIdle();
      unawaited(flush());
    });
  }

  Uri _endpoint(String path) {
    final base = serverUrl.path.endsWith('/')
        ? serverUrl.path.substring(0, serverUrl.path.length - 1)
        : serverUrl.path;
    return serverUrl.replace(path: '$base$path');
  }
}

enum _SendResult { delivered, rejected, retryLater }
