import 'package:meta/meta.dart';

import 'adapt_log_controller.dart';

/// Base comum de [AdaptLogInput] e [AdaptLogOutput].
///
/// Guarda o [AdaptLogController] recebido em [initialize] e o expõe às
/// subclasses via [controller]. Subclasses que sobrescrevem [initialize] ou
/// [shutdown] devem chamar `super`.
abstract class AdaptLogAdapter {
  AdaptLogController? _controller;

  /// Se já recebeu o controller em [initialize].
  bool get isAttached => _controller != null;

  /// Controller recebido em [initialize].
  ///
  /// Lança [StateError] se o adapter ainda não foi inicializado, isto é, se
  /// `AdaptLog.initialize()` ainda não foi aguardado.
  @protected
  AdaptLogController get controller {
    final controller = _controller;
    if (controller == null) {
      throw StateError(
        '$runtimeType ainda não foi inicializado. Registre-o em AdaptLog e '
        'aguarde AdaptLog.initialize() antes de usá-lo.',
      );
    }
    return controller;
  }

  /// Chamado por `AdaptLog.initialize()`. Outputs são inicializados antes
  /// dos inputs.
  @mustCallSuper
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
  }

  /// Chamado por `AdaptLog.shutdown()`, na ordem inversa de [initialize].
  @mustCallSuper
  Future<void> shutdown() async {}
}
