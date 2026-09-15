import 'package:adapt_log_real_time_remote_log_output_adapter/adapt_log_real_time_remote_log_output_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}
