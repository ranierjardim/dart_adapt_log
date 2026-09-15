import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_logger_package_output_adapter/adapt_log_logger_package_output_adapter.dart';


Future<void> main() async {
  final log = AdaptLogDefaultTextInputAdapter(
    printLevel: AdaptLogDefaultTextInputLevel.all,
    propagateLevel: AdaptLogDefaultTextInputLevel.all,
  );
  final loggerPackagePrinter = AdaptLogLoggerPackageOutputAdapter();
  final adaptLog = AdaptLog(
    adaptLogInputPorts: [
      log
    ],
    adaptLogOutputPorts: [
      loggerPackagePrinter,
    ],
    adaptLogDataPort: null,
  );
  await adaptLog.initialize();
  await log.shout('This is a example!!');
  await Future.delayed(const Duration(seconds: 1));
}
