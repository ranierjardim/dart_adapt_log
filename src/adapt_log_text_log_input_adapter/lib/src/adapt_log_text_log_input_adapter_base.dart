import 'package:adapt_log/adapt_log.dart';

class TextLogInputAdapter extends AdaptLogInput {
  late AdaptLogController _controller;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
  }

  @override
  Future<void> shutdown() async {}

  Future<void> debug(String message) async {
    await _controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.debug));
  }

  Future<void> info(String message) async {
    await _controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.info));
  }

  Future<void> warning(String message, {StackTrace? stackTrace}) async {
    await _controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.warning, stackTrace: stackTrace));
  }

  Future<void> error(String message, {StackTrace? stackTrace}) async {
    await _controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.error, stackTrace: stackTrace));
  }
}
