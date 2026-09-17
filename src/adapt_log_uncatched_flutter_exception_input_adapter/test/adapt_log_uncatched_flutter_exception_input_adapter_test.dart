import 'dart:ui';

import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_uncatched_flutter_exception_input_adapter/adapt_log_uncatched_flutter_exception_input_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

void main() {
  late FlutterExceptionHandler? previousOnError;
  late ErrorCallback? previousOnPlatformError;
  late List<FlutterErrorDetails> seenByPrevious;

  setUp(() {
    previousOnError = FlutterError.onError;
    previousOnPlatformError = PlatformDispatcher.instance.onError;
    seenByPrevious = [];
    FlutterError.onError = (details) => seenByPrevious.add(details);
    PlatformDispatcher.instance.onError = null;
  });

  tearDown(() {
    FlutterError.onError = previousOnError;
    PlatformDispatcher.instance.onError = previousOnPlatformError;
  });

  test('FlutterError.onError vira entry error e o handler anterior segue sendo chamado', () async {
    final out = Collector();
    final adaptLog = AdaptLog(inputs: [UncatchedFlutterExceptionInputAdapter()], outputs: [out]);
    await adaptLog.initialize();

    final stack = StackTrace.current;
    final failure = StateError('quebrou');
    FlutterError.reportError(FlutterErrorDetails(exception: failure, stack: stack));
    await adaptLog.flush();

    final entry = out.entries.single;
    expect(entry.level, AdaptLogLevel.error);
    expect(entry.message, contains('quebrou'));
    expect(entry.error, same(failure));
    expect(entry.errorType, 'StateError');
    expect(entry.stackTrace, same(stack));
    expect(entry.metadata['source'], 'FlutterError');
    expect(seenByPrevious, hasLength(1));
    await adaptLog.shutdown();
  });

  test('PlatformDispatcher.onError vira entry error e devolve false sem handler anterior', () async {
    final out = Collector();
    final adaptLog = AdaptLog(inputs: [UncatchedFlutterExceptionInputAdapter()], outputs: [out]);
    await adaptLog.initialize();

    final handled = PlatformDispatcher.instance.onError!(StateError('async'), StackTrace.current);
    await adaptLog.flush();

    expect(handled, isFalse);
    expect(out.entries.single.message, contains('async'));
    expect(out.entries.single.metadata['source'], 'PlatformDispatcher');
    await adaptLog.shutdown();
  });

  test('PlatformDispatcher.onError encadeia o handler anterior e devolve o resultado dele', () async {
    PlatformDispatcher.instance.onError = (error, stack) => true;
    final adaptLog = AdaptLog(inputs: [UncatchedFlutterExceptionInputAdapter()], outputs: const []);
    await adaptLog.initialize();

    expect(PlatformDispatcher.instance.onError!(StateError('x'), StackTrace.current), isTrue);
    await adaptLog.shutdown();
  });

  test('shutdown restaura os dois hooks', () async {
    final onErrorBefore = FlutterError.onError;
    final adaptLog = AdaptLog(inputs: [UncatchedFlutterExceptionInputAdapter()], outputs: const []);
    await adaptLog.initialize();
    expect(identical(FlutterError.onError, onErrorBefore), isFalse);
    expect(PlatformDispatcher.instance.onError, isNotNull);

    await adaptLog.shutdown();

    expect(identical(FlutterError.onError, onErrorBefore), isTrue);
    expect(PlatformDispatcher.instance.onError, isNull);
  });

  test('handleUncaughtError registra depois de initialize e encaminha ao FlutterError antes', () async {
    final adapter = UncatchedFlutterExceptionInputAdapter();
    final out = Collector();

    adapter.handleUncaughtError(StateError('cedo'), StackTrace.current);
    expect(seenByPrevious.single.exception.toString(), contains('cedo'));

    final adaptLog = AdaptLog(inputs: [adapter], outputs: [out]);
    await adaptLog.initialize();
    adapter.handleUncaughtError(StateError('tarde'), StackTrace.current);
    await adaptLog.flush();

    expect(out.entries.single.message, contains('tarde'));
    expect(out.entries.single.metadata['source'], 'zone');
    await adaptLog.shutdown();
  });
}
