// ignore_for_file: avoid_print

import 'dart:async';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_print_log_input_adapter/adapt_log_flutter_print_log_input_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  List<String> get messages => entries.map((e) => e.message).toList();

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

/// Output que escreve no console com print(), como o package logger.
class PrintingOutput extends AdaptLogOutput {
  int calls = 0;

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    calls++;
    print('[${entry.level.name}] ${entry.message}');
  }
}

void main() {
  late DebugPrintCallback previousDebugPrint;
  late List<String?> printedByOriginal;

  setUp(() {
    previousDebugPrint = debugPrint;
    printedByOriginal = [];
    debugPrint = (String? message, {int? wrapWidth}) => printedByOriginal.add(message);
  });

  tearDown(() => debugPrint = previousDebugPrint);

  test('captura debugPrint como entry debug e mantém a saída original', () async {
    final adapter = FlutterPrintLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(inputs: [adapter], outputs: [out]);
    await adaptLog.initialize();

    debugPrint('olá');
    await adaptLog.flush();

    expect(out.messages, ['olá']);
    expect(out.entries.single.level, AdaptLogLevel.debug);
    expect(printedByOriginal, ['olá']);
    await adaptLog.shutdown();
  });

  test('shutdown restaura o debugPrint anterior', () async {
    final before = debugPrint;
    final adaptLog = AdaptLog(inputs: [FlutterPrintLogInputAdapter()], outputs: const []);
    await adaptLog.initialize();
    expect(identical(debugPrint, before), isFalse);

    await adaptLog.shutdown();

    expect(identical(debugPrint, before), isTrue);
  });

  test('shutdown não derruba um hook instalado por cima do nosso', () async {
    final adaptLog = AdaptLog(inputs: [FlutterPrintLogInputAdapter()], outputs: const []);
    await adaptLog.initialize();
    void otherHook(String? message, {int? wrapWidth}) {}
    debugPrint = otherHook;

    await adaptLog.shutdown();

    expect(identical(debugPrint, otherHook), isTrue);
  });

  test('zoneSpecification captura print() e não duplica debugPrint()', () async {
    final adapter = FlutterPrintLogInputAdapter();
    final out = Collector();
    final adaptLog = AdaptLog(inputs: [adapter], outputs: [out]);
    await adaptLog.initialize();
    // debugPrint real: termina em print(), que a zona intercepta.
    debugPrint = debugPrintSynchronously;

    final printed = <String>[];
    runZoned(
      () {
        print('via print');
        debugPrint('via debugPrint');
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          adapter.zoneSpecification.print!(self, parent, zone, line);
        },
      ),
    );
    await adaptLog.flush();

    expect(out.messages, ['via print', 'via debugPrint']);
    await adaptLog.shutdown();
    expect(printed, isEmpty);
  });

  test('output que imprime dentro da zona não gera loop', () async {
    final adapter = FlutterPrintLogInputAdapter();
    final printing = PrintingOutput();
    final out = Collector();
    final adaptLog = AdaptLog(inputs: [adapter], outputs: [printing, out]);
    await adaptLog.initialize();

    await runZoned(
      () async {
        print('uma linha');
        await adaptLog.flush();
      },
      zoneSpecification: adapter.zoneSpecification,
    );

    expect(printing.calls, 1);
    expect(out.messages, ['uma linha']);
    await adaptLog.shutdown();
  });
}
