import 'dart:async';

import 'package:adapt_log_remote_protocol/adapt_log_remote_protocol.dart';

/// Difunde ao vivo as entries aceitas, para o painel.
class LogStream {
  final StreamController<LogStreamEvent> _controller = StreamController<LogStreamEvent>.broadcast();

  Stream<LogStreamEvent> forProject(String project) {
    return _controller.stream.where((event) => event.project == project);
  }

  void publish(LogStreamEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> close() => _controller.close();
}
