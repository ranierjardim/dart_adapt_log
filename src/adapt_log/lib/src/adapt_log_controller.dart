import 'adapt_log.dart';
import 'adapt_log_entry.dart';

class AdaptLogController {
  final AdaptLog _instance;

  const AdaptLogController(this._instance);

  Future<void> log(AdaptLogEntry entry) async {
    var enriched = entry;
    for (final input in _instance.inputs) {
      enriched = input.enrichEntry(enriched);
    }
    for (final output in _instance.outputs) {
      await output.onNewLog(enriched);
    }
  }
}
