library adapt_log_flutter_error_screenshot_input_adapter;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:adapt_log/adapt_log.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Captura a tela a cada entry de nível `error` e a emite como uma entry
/// própria, de nível `info`, ligada ao erro por `metadata['screenshotFor']`.
///
/// A imagem vai em `metadata['screenshot']` como PNG em base64, com
/// `screenshotFormat`, `screenshotWidth` e `screenshotHeight`. O
/// adapt_log_server extrai a imagem, marca a entry de erro com
/// `hasScreenshot` e o painel a exibe como "Tela no momento do erro".
///
/// A captura espera o frame em andamento terminar, então um erro de build
/// mostra a tela como ficou depois do erro. Erros em sequência respeitam
/// [minInterval]. Reports e screenshots não disparam captura.
///
/// Envolva a app em [AdaptLogScreenshotBoundary] para capturar só a árvore da
/// app; sem isso, a raiz da renderização é usada.
class FlutterErrorScreenshotInputAdapter extends AdaptLogInput {
  static const String isScreenshotKey = 'isScreenshot';
  static const String screenshotForKey = 'screenshotFor';
  static const String screenshotKey = 'screenshot';
  static const String formatKey = 'screenshotFormat';
  static const String widthKey = 'screenshotWidth';
  static const String heightKey = 'screenshotHeight';

  /// Pixels da imagem por pixel lógico da tela. `1.0` gera a imagem no
  /// tamanho lógico; valores menores reduzem o PNG.
  final double pixelRatio;

  /// Intervalo mínimo entre capturas; erros dentro dele não geram imagem.
  final Duration minInterval;

  /// Chave do `RepaintBoundary` montado por [AdaptLogScreenshotBoundary].
  final GlobalKey boundaryKey = GlobalKey(debugLabel: 'AdaptLogScreenshotBoundary');

  DateTime? _lastCapture;
  bool _capturing = false;
  int _captured = 0;
  int _skipped = 0;

  FlutterErrorScreenshotInputAdapter({
    this.pixelRatio = 1.0,
    this.minInterval = const Duration(seconds: 2),
  }) : assert(pixelRatio > 0);

  /// Capturas emitidas desde o `initialize()`.
  int get capturedScreenshots => _captured;

  /// Erros que não geraram captura por [minInterval], captura em andamento
  /// ou ausência de tela renderizada.
  int get skippedScreenshots => _skipped;

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    if (entry.level == AdaptLogLevel.error &&
        entry.metadata['isReport'] != true &&
        entry.metadata[isScreenshotKey] != true) {
      unawaited(_captureFor(entry));
    }
    return entry;
  }

  Future<void> _captureFor(AdaptLogEntry error) async {
    final now = DateTime.now();
    final last = _lastCapture;
    if (_capturing || (last != null && now.difference(last) < minInterval)) {
      _skipped++;
      return;
    }
    _capturing = true;
    _lastCapture = now;
    try {
      final image = await capture();
      if (image == null) {
        _skipped++;
        return;
      }
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) {
          _skipped++;
          return;
        }
        final png = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        _captured++;
        await controller.log(AdaptLogEntry(
          message: 'Screenshot: ${error.message}',
          level: AdaptLogLevel.info,
          metadata: {
            isScreenshotKey: true,
            screenshotForKey: error.id,
            formatKey: 'png',
            widthKey: image.width,
            heightKey: image.height,
            screenshotKey: base64Encode(png),
          },
        ));
      } finally {
        image.dispose();
      }
    } catch (e, s) {
      controller.reportError(e, s, this);
    } finally {
      _capturing = false;
    }
  }

  /// Captura a tela atual. Se um frame estiver em andamento, espera ele
  /// terminar. Retorna `null` quando não há nada renderizado.
  Future<ui.Image?> capture() async {
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.idle) {
      await scheduler.endOfFrame;
    }
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary && boundary.hasSize) {
      return boundary.toImage(pixelRatio: pixelRatio);
    }
    final views = RendererBinding.instance.renderViews;
    if (views.isEmpty) return null;
    final view = views.first;
    // `layer` é protegido para quem estende RenderObject; aqui só lemos o
    // layer raiz já pintado para rasterizá-lo.
    // ignore: invalid_use_of_protected_member
    final layer = view.layer;
    if (layer is! OffsetLayer) return null;
    // O layer raiz trabalha em pixels físicos; divide pelo devicePixelRatio
    // para que pixelRatio signifique "pixels por pixel lógico" nos dois casos.
    final devicePixelRatio = view.configuration.devicePixelRatio;
    return layer.toImage(view.paintBounds, pixelRatio: pixelRatio / devicePixelRatio);
  }
}

/// Delimita a área capturada por [FlutterErrorScreenshotInputAdapter].
///
/// ```dart
/// runApp(AdaptLogScreenshotBoundary(adapter: screenshotAdapter, child: const MyApp()));
/// ```
class AdaptLogScreenshotBoundary extends StatelessWidget {
  final FlutterErrorScreenshotInputAdapter adapter;
  final Widget child;

  const AdaptLogScreenshotBoundary({super.key, required this.adapter, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: adapter.boundaryKey, child: child);
  }
}
