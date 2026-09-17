import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_error_screenshot_input_adapter/adapt_log_flutter_error_screenshot_input_adapter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Os testes fazem o trabalho assíncrono real (rasterização) dentro de
// `tester.runAsync`, inclusive o `shutdown()`: aguardar fora do runAsync um
// future concluído dentro dele trava o harness de fake async.

class Emitter extends AdaptLogInput {
  Future<void> emit(String message, {AdaptLogLevel level = AdaptLogLevel.error, Map<String, dynamic>? metadata}) {
    return controller.log(AdaptLogEntry(message: message, level: level, metadata: metadata));
  }
}

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

const _pngSignature = 'iVBORw0KGgo';

Future<void> waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  const timeout = Timeout(Duration(seconds: 30));

  testWidgets('captura a tela após um erro e emite entry ligada por screenshotFor', (tester) async {
    final emitter = Emitter();
    final out = Collector();
    final errors = <Object>[];
    final screenshot = FlutterErrorScreenshotInputAdapter(minInterval: Duration.zero);
    final adaptLog = AdaptLog(
      inputs: [emitter, screenshot],
      outputs: [out],
      onError: (error, _, __) => errors.add(error),
    );
    await adaptLog.initialize();
    await tester.pumpWidget(AdaptLogScreenshotBoundary(
      adapter: screenshot,
      child: const ColoredBox(color: Color(0xFF2196F3), child: SizedBox.expand()),
    ));

    await tester.runAsync(() async {
      await emitter.emit('boom');
      await waitUntil(() => out.entries.length >= 2);
      await adaptLog.shutdown();
    });

    expect(errors, isEmpty);
    expect(out.entries, hasLength(2));
    final error = out.entries[0];
    final shot = out.entries[1];
    expect(shot.level, AdaptLogLevel.info);
    expect(shot.message, 'Screenshot: boom');
    expect(shot.metadata['isScreenshot'], isTrue);
    expect(shot.metadata['screenshotFor'], error.id);
    expect(shot.metadata['screenshotFormat'], 'png');
    expect(shot.metadata['screenshotWidth'], 800);
    expect(shot.metadata['screenshotHeight'], 600);
    expect(shot.metadata['screenshot'], startsWith(_pngSignature));
    expect(screenshot.capturedScreenshots, 1);
  }, timeout: timeout);

  testWidgets('sem boundary captura a raiz da renderização; pixelRatio reduz a imagem', (tester) async {
    final emitter = Emitter();
    final out = Collector();
    final screenshot = FlutterErrorScreenshotInputAdapter(minInterval: Duration.zero, pixelRatio: 0.5);
    final adaptLog = AdaptLog(inputs: [emitter, screenshot], outputs: [out]);
    await adaptLog.initialize();
    await tester.pumpWidget(const ColoredBox(color: Color(0xFFFF9800), child: SizedBox.expand()));

    await tester.runAsync(() async {
      await emitter.emit('boom');
      await waitUntil(() => out.entries.length >= 2);
      await adaptLog.shutdown();
    });

    expect(out.entries, hasLength(2));
    final shot = out.entries[1];
    expect(shot.metadata['screenshotWidth'], 400);
    expect(shot.metadata['screenshotHeight'], 300);
    expect(shot.metadata['screenshot'], startsWith(_pngSignature));
  }, timeout: timeout);

  testWidgets('minInterval limita capturas em sequência', (tester) async {
    final emitter = Emitter();
    final out = Collector();
    final screenshot = FlutterErrorScreenshotInputAdapter(minInterval: const Duration(minutes: 10));
    final adaptLog = AdaptLog(inputs: [emitter, screenshot], outputs: [out]);
    await adaptLog.initialize();
    await tester.pumpWidget(const SizedBox.expand());

    await tester.runAsync(() async {
      await emitter.emit('primeiro');
      await emitter.emit('segundo');
      await waitUntil(() => out.entries.length >= 3);
      await adaptLog.shutdown();
    });

    expect(out.entries.where((e) => e.metadata['isScreenshot'] == true), hasLength(1));
    expect(screenshot.capturedScreenshots, 1);
    expect(screenshot.skippedScreenshots, 1);
  }, timeout: timeout);

  testWidgets('reports, screenshots e níveis abaixo de error não disparam captura', (tester) async {
    final emitter = Emitter();
    final out = Collector();
    final screenshot = FlutterErrorScreenshotInputAdapter(minInterval: Duration.zero);
    final adaptLog = AdaptLog(inputs: [emitter, screenshot], outputs: [out]);
    await adaptLog.initialize();
    await tester.pumpWidget(const SizedBox.expand());

    await tester.runAsync(() async {
      await emitter.emit('aviso', level: AdaptLogLevel.warning);
      await emitter.emit('report', metadata: {'isReport': true});
      await emitter.emit('shot', metadata: {'isScreenshot': true});
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await adaptLog.shutdown();
    });

    expect(out.entries, hasLength(3));
    expect(screenshot.capturedScreenshots, 0);
  }, timeout: timeout);
}
