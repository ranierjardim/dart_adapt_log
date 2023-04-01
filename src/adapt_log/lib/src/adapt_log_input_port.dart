

import 'package:adapt_log/src/adapt_log_controller.dart';

abstract class AdaptLogInputPort {

  Future<void> initialize(AdaptLogController adaptLogController);

  Future<void> shutdown();

}