

import 'package:adapt_log/adapt_log.dart';

abstract class AdaptLogDataPort {

  Future<void> initialize(AdaptLogController adaptLogController);

  Future<void> shutdown();

  Future<void> onNewLog(AdaptLogObjectMixin object);

  Future<List<dynamic>> getLogObjects();

}