import 'adapt_log_controller.dart';
import 'adapt_log_entry.dart';

abstract class AdaptLogInput {
  Future<void> initialize(AdaptLogController controller);

  Future<void> shutdown();

  AdaptLogEntry enrichEntry(AdaptLogEntry entry) => entry;
}
