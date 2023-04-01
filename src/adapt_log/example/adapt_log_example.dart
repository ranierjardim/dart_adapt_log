import 'package:adapt_log/adapt_log.dart';

Future<void> main() async {
  final log = AdaptLogDefaultTextInputAdapter();
  final consolePrinter = AdaptLogConsolePrintOutputAdapter();
  final adaptLog = AdaptLog(
    adaptLogInputPorts: [
      log
    ],
    adaptLogOutputPorts: [
      consolePrinter,
    ],
    adaptLogDataPort: null,
  );
  await adaptLog.initialize();
  await log.shout('This is a example!!');
}
