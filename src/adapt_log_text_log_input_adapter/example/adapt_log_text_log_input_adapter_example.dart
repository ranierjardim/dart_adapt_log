import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

class _ConsolePrint extends AdaptLogOutput {
  @override
  Future<void> initialize(AdaptLogController controller) async {}
  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    print('[${entry.level.name.toUpperCase()}] ${entry.message}');
  }
  @override
  Future<void> shutdown() async {}
}

Future<void> main() async {
  final log = TextLogInputAdapter();
  final adaptLog = AdaptLog(inputs: [log], outputs: [_ConsolePrint()]);
  await adaptLog.initialize();

  await log.info('Usuário autenticado com sucesso');
  await log.warning('Token próximo do vencimento');
  await log.error('Falha ao conectar ao servidor');
  await log.debug('Payload: {userId: 42}');
}
