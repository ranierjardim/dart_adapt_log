import 'adapt_log_controller.dart';
import 'adapt_log_input.dart';
import 'adapt_log_output.dart';

class AdaptLog {
  bool _initialized = false;
  final List<AdaptLogInput> inputs;
  final List<AdaptLogOutput> outputs;
  late final AdaptLogController controller;

  AdaptLog({required this.inputs, required this.outputs}) {
    controller = AdaptLogController(this);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    for (final output in outputs) {
      await output.initialize(controller);
    }
    for (final input in inputs) {
      await input.initialize(controller);
    }
    _initialized = true;
  }

  Future<void> shutdown() async {
    for (final input in inputs) {
      await input.shutdown();
    }
    for (final output in outputs) {
      await output.shutdown();
    }
  }
}
