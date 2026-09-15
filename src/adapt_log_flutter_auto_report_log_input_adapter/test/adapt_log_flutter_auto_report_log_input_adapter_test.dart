import 'package:flutter_test/flutter_test.dart';
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:adapt_log_flutter_auto_report_log_input_adapter/adapt_log_flutter_auto_report_log_input_adapter.dart';

void main() {
  group('FlutterAutoReportLogInputAdapter', () {
    test('instancia sem erros', () {
      final reportAdapter = ReportLogInputAdapter();
      final adapter = FlutterAutoReportLogInputAdapter(
        reportAdapter: reportAdapter,
      );
      expect(adapter, isNotNull);
    });

    test('retorna entry sem modificação quando nível não é error', () async {
      final reportAdapter = ReportLogInputAdapter();
      final adapter = FlutterAutoReportLogInputAdapter(
        reportAdapter: reportAdapter,
      );

      final entry = AdaptLogEntry(
        message: 'mensagem info',
        level: AdaptLogLevel.info,
      );

      final result = adapter.enrichEntry(entry);
      expect(result.message, equals(entry.message));
      expect(result.level, equals(AdaptLogLevel.info));
    });

    test('não dispara report quando metadata isReport já é true', () async {
      final reportAdapter = ReportLogInputAdapter();
      final adapter = FlutterAutoReportLogInputAdapter(
        reportAdapter: reportAdapter,
      );

      final entry = AdaptLogEntry(
        message: 'report entry',
        level: AdaptLogLevel.error,
        metadata: {'isReport': true},
      );

      // não deve lançar exceção mesmo sem controller inicializado
      expect(() => adapter.enrichEntry(entry), returnsNormally);
    });
  });
}
