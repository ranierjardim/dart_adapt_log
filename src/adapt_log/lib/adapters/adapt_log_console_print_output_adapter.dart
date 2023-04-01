import 'package:adapt_log/adapt_log.dart';

class AdaptLogConsolePrintOutputAdapter extends AdaptLogOutputPort {
  @override
  Future<void> initialize(AdaptLogController adaptLogController) async {

  }

  @override
  Future<void> onNewLog(AdaptLogObjectMixin object) async {
    if(object is AdaptLogDefaultTextInputObjectMixin) {
      if(object.shouldPrint) {
        print('[${object.defaultTextInputLevel.asString()}][${object.currentTime}]: ${object.toLogString}\n');
      }
    } else {
      print('[${object.currentTime}]: ${object.toLogString}\n');
    }
  }

  @override
  Future<void> shutdown() async {

  }
}