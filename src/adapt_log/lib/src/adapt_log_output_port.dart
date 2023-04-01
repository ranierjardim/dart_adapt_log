

import 'package:adapt_log/adapt_log.dart';

abstract class AdaptLogOutputPort {

  Future<void> initialize(AdaptLogController adaptLogController);

  Future<void> shutdown();

  Future<void> onNewLog(AdaptLogObjectMixin object);

}