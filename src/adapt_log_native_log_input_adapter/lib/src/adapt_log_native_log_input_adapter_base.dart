import 'package:adapt_log/adapt_log.dart';

class NativeLogInputAdapter extends AdaptLogInput {
  late AdaptLogController _controller;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
    // TODO: Implement platform channel to receive native logs.
    // Android: bridge to Logcat via MethodChannel/EventChannel.
    // iOS: bridge to os_log / NSLog via MethodChannel/EventChannel.
  }

  @override
  Future<void> shutdown() async {}

  void _dispatch(String message, AdaptLogLevel level) {
    _controller.log(AdaptLogEntry(message: message, level: level));
  }
}
