import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_logger_print_package_output_adapter/adapt_log_logger_print_package_output_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

Future<void> main() async {
  final log = TextLogInputAdapter();

  final adaptLog = AdaptLog(
    inputs: [log],
    outputs: [LoggerPrintOutputAdapter()],
  );
  await adaptLog.initialize();

  await log.info('Aplicação iniciada');
  await log.warning('Aviso de exemplo');
  await log.error('Erro de exemplo');
  await log.debug('Debug de exemplo');
}
