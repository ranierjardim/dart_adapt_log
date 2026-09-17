import 'adapt_log_adapter.dart';
import 'adapt_log_entry.dart';

/// Contrato dos adapters de entrada: fontes de log.
///
/// Um input emite entries chamando `controller.log(entry)`. Opcionalmente
/// pode enriquecer todas as entries do pipeline sobrescrevendo [enrichEntry].
abstract class AdaptLogInput extends AdaptLogAdapter {
  /// Chamado para cada entry, na ordem em que os inputs foram registrados,
  /// antes do despacho aos outputs. Deve ser síncrono e não lançar; uma
  /// exceção aqui é reportada em `AdaptLog.onError` e a entry segue sem
  /// este enriquecimento.
  ///
  /// Chamar `controller.log()` daqui é permitido: a nova entry entra na fila
  /// e é despachada depois da entry atual.
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) => entry;
}
