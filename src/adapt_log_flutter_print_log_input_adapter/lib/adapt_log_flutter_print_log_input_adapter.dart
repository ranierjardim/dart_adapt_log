library adapt_log_flutter_print_log_input_adapter;

import 'dart:async';

import 'package:adapt_log/adapt_log.dart';
import 'package:flutter/foundation.dart';

/// Intercepta `debugPrint()` e, opcionalmente, `print()` e os emite como
/// entries de nível `debug`.
///
/// A saída original continua chegando ao console: o hook de `debugPrint`
/// chama a implementação anterior e o [zoneSpecification] delega ao `print`
/// da zona pai. Outputs que imprimem no console durante o despacho não geram
/// novas entries, porque o core descarta `log()` re-entrante.
///
/// Erros do framework e exceções não tratadas não são tratados aqui; use
/// adapt_log_uncatched_flutter_exception_input_adapter.
class FlutterPrintLogInputAdapter extends AdaptLogInput {
  static final Object _fromDebugPrint = Object();

  DebugPrintCallback? _originalDebugPrint;
  DebugPrintCallback? _hook;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    final original = _originalDebugPrint = debugPrint;
    debugPrint = _hook = (String? message, {int? wrapWidth}) {
      if (message != null) _dispatch(message);
      // A implementação original acaba chamando print(); a zona marcada evita
      // que o zoneSpecification registre a mesma linha duas vezes.
      runZoned(
        () => original(message, wrapWidth: wrapWidth),
        zoneValues: {_fromDebugPrint: true},
      );
    };
  }

  @override
  Future<void> shutdown() async {
    // Só restaura se nenhum outro hook foi instalado por cima do nosso.
    if (identical(debugPrint, _hook)) {
      debugPrint = _originalDebugPrint ?? debugPrintThrottled;
    }
    _hook = null;
    _originalDebugPrint = null;
    await super.shutdown();
  }

  /// ZoneSpecification que captura `print()` na zona da app:
  ///
  /// ```dart
  /// runZoned(
  ///   () => runApp(const MyApp()),
  ///   zoneSpecification: adapter.zoneSpecification,
  /// );
  /// ```
  ZoneSpecification get zoneSpecification => ZoneSpecification(
        print: (self, parent, zone, line) {
          if (Zone.current[_fromDebugPrint] != true) _dispatch(line);
          parent.print(zone, line);
        },
      );

  void _dispatch(String message) {
    if (!isAttached) return;
    controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.debug));
  }
}
