import 'adapt_log_controller.dart';
import 'adapt_log_entry.dart';

abstract class AdaptLogOutput {
  Future<void> initialize(AdaptLogController controller);

  Future<void> shutdown();

  Future<void> onNewLog(AdaptLogEntry entry);
}
