import 'adapt_log_adapter.dart';
import 'adapt_log_entry.dart';

/// Contrato dos adapters de saída: destinos de log.
///
/// Para cada output, [onNewLog] é chamado uma entry por vez, na ordem em que
/// foram logadas; outputs diferentes não bloqueiam uns aos outros. Exceções,
/// síncronas ou assíncronas, são isoladas e reportadas em `AdaptLog.onError`.
///
/// Um output não deve logar pelo pipeline: qualquer `controller.log()` feito
/// durante [onNewLog], direta ou indiretamente (por exemplo via um `print()`
/// interceptado por um input), é descartado para evitar recursão infinita.
abstract class AdaptLogOutput extends AdaptLogAdapter {
  Future<void> onNewLog(AdaptLogEntry entry);
}
