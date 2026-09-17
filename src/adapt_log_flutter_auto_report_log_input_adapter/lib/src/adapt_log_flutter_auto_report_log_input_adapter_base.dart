import 'dart:collection';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_auto_report_log_input_adapter/adapt_log_auto_report_log_input_adapter.dart';
import 'package:flutter/foundation.dart';

/// [AutoReportLogInputAdapter] que guarda as últimas linhas impressas via
/// `debugPrint` e as anexa a cada entry de erro, em `metadata['recentPrints']`,
/// e ao contexto do report disparado.
///
/// O hook de `debugPrint` chama a implementação anterior, então a saída no
/// console é preservada. Requer o mesmo setup do adapter base: o
/// `ReportLogInputAdapter` registrado em `AdaptLog.inputs`.
class FlutterAutoReportLogInputAdapter extends AutoReportLogInputAdapter {
  /// Chave da metadata onde as linhas recentes de `debugPrint` são anexadas.
  static const String recentPrintsKey = 'recentPrints';

  /// Número máximo de linhas de `debugPrint` mantidas no buffer circular.
  final int maxPrintBuffer;

  final ListQueue<String> _printBuffer;
  DebugPrintCallback? _originalDebugPrint;
  DebugPrintCallback? _hook;

  FlutterAutoReportLogInputAdapter({
    required super.reportAdapter,
    this.maxPrintBuffer = 50,
  })  : assert(maxPrintBuffer > 0),
        _printBuffer = ListQueue<String>(maxPrintBuffer);

  /// Linhas atualmente no buffer, da mais antiga para a mais recente.
  List<String> get recentPrints => List<String>.unmodifiable(_printBuffer);

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    final original = _originalDebugPrint = debugPrint;
    debugPrint = _hook = (String? message, {int? wrapWidth}) {
      if (message != null) {
        if (_printBuffer.length == maxPrintBuffer) _printBuffer.removeFirst();
        _printBuffer.addLast(message);
      }
      original(message, wrapWidth: wrapWidth);
    };
  }

  @override
  Future<void> shutdown() async {
    // Só restaura se nenhum outro hook foi instalado por cima do nosso.
    if (identical(debugPrint, _hook)) {
      debugPrint = _originalDebugPrint ?? debugPrintThrottled;
    }
    _hook = null;
    _originalDebugPrint = null;
    _printBuffer.clear();
    await super.shutdown();
  }

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    var enriched = entry;
    if (entry.level == AdaptLogLevel.error &&
        entry.metadata['isReport'] != true &&
        _printBuffer.isNotEmpty &&
        !entry.metadata.containsKey(recentPrintsKey)) {
      enriched = entry.copyWith(metadata: {
        ...entry.metadata,
        recentPrintsKey: List<String>.unmodifiable(_printBuffer),
      });
    }
    return super.enrichEntry(enriched);
  }

  @override
  String buildReportContext(AdaptLogEntry entry) {
    final base = super.buildReportContext(entry);
    if (_printBuffer.isEmpty) return base;
    final lines = _printBuffer.map((line) => '  $line').join('\n');
    return '$base\n\nFlutter output (últimas ${_printBuffer.length} linhas):\n$lines';
  }
}
