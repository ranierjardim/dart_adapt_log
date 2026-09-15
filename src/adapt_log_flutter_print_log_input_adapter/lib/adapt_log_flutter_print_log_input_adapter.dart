library adapt_log_flutter_print_log_input_adapter;

import 'dart:async';

import 'package:adapt_log/adapt_log.dart';
import 'package:flutter/foundation.dart';

class FlutterPrintLogInputAdapter extends AdaptLogInput {
  late AdaptLogController _controller;
  late DebugPrintCallback _originalDebugPrint;
  FlutterExceptionHandler? _originalOnError;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
    _originalDebugPrint = debugPrint;
    _originalOnError = FlutterError.onError;

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) _dispatch(message, AdaptLogLevel.debug);
    };

    FlutterError.onError = (FlutterErrorDetails details) {
      _dispatch(details.exceptionAsString(), AdaptLogLevel.error);
      _originalOnError?.call(details) ?? FlutterError.presentError(details);
    };
  }

  /// ZoneSpecification para capturar chamadas a print() dentro da zona da app.
  /// Use com runZoned() no main() para cobertura completa:
  ///
  /// ```dart
  /// runZoned(
  ///   () => runApp(const MyApp()),
  ///   zoneSpecification: adapter.zoneSpecification,
  /// );
  /// ```
  ZoneSpecification get zoneSpecification => ZoneSpecification(
        print: (self, parent, zone, line) {
          _dispatch(line, AdaptLogLevel.debug);
          parent.print(zone, line);
        },
      );

  @override
  Future<void> shutdown() async {
    debugPrint = _originalDebugPrint;
    FlutterError.onError = _originalOnError;
  }

  void _dispatch(String message, AdaptLogLevel level) {
    _controller.log(AdaptLogEntry(message: message, level: level));
  }
}
