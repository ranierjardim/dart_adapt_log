import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_real_time_remote_log_output_adapter/adapt_log_real_time_remote_log_output_adapter.dart';

class _Emitter extends AdaptLogInput {
  Future<void> error(String message, {Object? error, StackTrace? stackTrace}) {
    return controller.log(AdaptLogEntry(
      message: message,
      level: AdaptLogLevel.error,
      error: error,
      stackTrace: stackTrace,
    ));
  }
}

Future<void> main() async {
  final emitter = _Emitter();
  final adaptLog = AdaptLog(
    inputs: [emitter],
    outputs: [
      RealTimeRemoteLogOutputAdapter(
        serverUrl: 'http://localhost:8080',
        apiKey: 'dev-key',
        sessionMetadata: {'app.name': 'exemplo'},
      ),
    ],
  );
  await adaptLog.initialize();

  try {
    throw StateError('falha de exemplo');
  } catch (error, stackTrace) {
    await emitter.error('Algo deu errado', error: error, stackTrace: stackTrace);
  }

  // shutdown envia o que ainda estiver na fila.
  await adaptLog.shutdown();
}
