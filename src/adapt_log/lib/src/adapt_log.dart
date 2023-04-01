import 'package:adapt_log/adapt_log.dart';

class AdaptLog {

  bool _initialized = false;
  final AdaptLogDataPort? adaptLogDataPort;
  final List<AdaptLogInputPort> adaptLogInputPorts;
  final List<AdaptLogOutputPort> adaptLogOutputPorts;
  late final AdaptLogController adaptLogController;

  AdaptLog({required this.adaptLogInputPorts, required this.adaptLogOutputPorts, this.adaptLogDataPort}) {
    adaptLogController = AdaptLogController(this);
  }

  Future<void> initialize() async {
    if(_initialized) {
      return;
    }
    if(adaptLogDataPort != null) {
      await adaptLogDataPort!.initialize(adaptLogController);
    }
    for (final adapter in adaptLogOutputPorts) {
      await adapter.initialize(adaptLogController);
    }
    for (final adapter in adaptLogInputPorts) {
      await adapter.initialize(adaptLogController);
    }
    _initialized = true;
  }

  Future<void> shutdown() async {

  }
}
