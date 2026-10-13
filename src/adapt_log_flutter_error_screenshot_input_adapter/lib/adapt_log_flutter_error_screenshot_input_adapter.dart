library adapt_log_flutter_error_screenshot_input_adapter;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:adapt_log/adapt_log.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Captura a tela a cada entry de nível `error` e a emite como uma entry
/// própria, de nível `info`, ligada ao erro por `metadata['screenshotFor']`.
///
/// A imagem vai em `metadata['screenshot']` como PNG em base64, com
/// `screenshotFormat`, `screenshotWidth`, `screenshotHeight`, o UUID do quadro
/// em `screenshotId` e o horário da captura em `screenshotCapturedAt`. O
/// adapt_log_server extrai a imagem, marca a entry de erro com
/// `hasScreenshot` e o painel a exibe.
///
/// ## Histórico de quadros
///
/// Com [historyFrames] maior que zero, o adapter também captura a tela a cada
/// [historyInterval] e guarda os últimos [historyFrames] quadros **sem
/// codificar** (a imagem rasterizada fica na memória; o PNG só é gerado se
/// houver erro). Cada captura gera uma linha de log, de nível
/// [historyLogLevel], com a mensagem `Capturado quadro da tela - UUID <uuid>`
/// e o horário, para cruzar o quadro com o que o app registrava na hora.
///
/// Quando um erro é logado, o adapter captura mais um quadro e emite uma entry
/// de screenshot para cada quadro do histórico e para o do erro, em ordem
/// cronológica, todas ligadas ao erro. Cada uma leva o próprio UUID, o horário
/// em que foi capturada (também no `timestamp` da entry), a posição
/// (`screenshotIndex` de `screenshotCount`) e `screenshotMoment`: `history` ou
/// `error`.
///
/// Só os frames do próprio Flutter são lidos: não é gravação de tela do
/// sistema e não pede permissão. Com o app fora do primeiro plano nada é
/// capturado.
///
/// A captura do erro espera o frame em andamento terminar, então um erro de
/// build mostra a tela como ficou depois do erro. Erros em sequência
/// respeitam [minInterval]. Reports e screenshots não disparam captura.
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

  /// UUID do quadro, o mesmo da linha `Capturado quadro da tela - UUID ...`.
  static const String idKey = 'screenshotId';

  /// Horário (UTC, ISO 8601) em que o quadro foi capturado.
  static const String capturedAtKey = 'screenshotCapturedAt';

  /// Posição do quadro entre os anexados ao erro, a partir de 1.
  static const String indexKey = 'screenshotIndex';

  /// Quantos quadros foram anexados ao erro.
  static const String countKey = 'screenshotCount';

  /// `history` (quadro guardado antes do erro) ou `error` (capturado no erro).
  static const String momentKey = 'screenshotMoment';

  /// Marca a linha de log de uma captura do histórico.
  static const String isFrameCaptureKey = 'isFrameCapture';

  /// UUID do quadro na linha de log da captura.
  static const String frameIdKey = 'frameId';

  /// Horário (UTC, ISO 8601) do quadro na linha de log da captura.
  static const String frameCapturedAtKey = 'frameCapturedAt';

  /// Pixels da imagem por pixel lógico da tela. `1.0` gera a imagem no
  /// tamanho lógico; valores menores reduzem o PNG e a memória do histórico.
  final double pixelRatio;

  /// Intervalo mínimo entre capturas de erro; erros dentro dele não geram
  /// imagem.
  final Duration minInterval;

  /// Quantos quadros anteriores ao erro são guardados. `0` desliga o
  /// histórico: só a tela no momento do erro é capturada.
  final int historyFrames;

  /// De quanto em quanto tempo um quadro do histórico é capturado.
  final Duration historyInterval;

  /// Nível da linha de log de cada captura do histórico.
  final AdaptLogLevel historyLogLevel;

  /// Chave do `RepaintBoundary` montado por [AdaptLogScreenshotBoundary].
  final GlobalKey boundaryKey = GlobalKey(debugLabel: 'AdaptLogScreenshotBoundary');

  final List<_Frame> _history = [];
  Timer? _historyTimer;
  DateTime? _lastCapture;
  bool _capturing = false;
  bool _capturingHistory = false;
  int _captured = 0;
  int _skipped = 0;

  FlutterErrorScreenshotInputAdapter({
    this.pixelRatio = 1.0,
    this.minInterval = const Duration(seconds: 2),
    this.historyFrames = 0,
    this.historyInterval = const Duration(seconds: 2),
    this.historyLogLevel = AdaptLogLevel.debug,
  })  : assert(pixelRatio > 0),
        assert(historyFrames >= 0);

  /// Entries de screenshot emitidas desde o `initialize()`.
  int get capturedScreenshots => _captured;

  /// Erros que não geraram captura por [minInterval], captura em andamento
  /// ou ausência de tela renderizada.
  int get skippedScreenshots => _skipped;

  /// UUIDs dos quadros guardados no histórico, do mais antigo ao mais novo.
  List<String> get historyFrameIds => [for (final frame in _history) frame.id];

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    if (historyFrames > 0) {
      _historyTimer = Timer.periodic(historyInterval, (_) => unawaited(captureHistoryFrame()));
    }
  }

  @override
  Future<void> shutdown() async {
    _historyTimer?.cancel();
    _historyTimer = null;
    for (final frame in _history) {
      frame.image.dispose();
    }
    _history.clear();
    await super.shutdown();
  }

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    if (entry.level == AdaptLogLevel.error &&
        entry.metadata['isReport'] != true &&
        entry.metadata[isScreenshotKey] != true) {
      unawaited(_captureFor(entry));
    }
    return entry;
  }

  /// Captura um quadro para o histórico e registra a linha de log dele. É o
  /// que o temporizador chama a cada [historyInterval]; retorna o UUID do
  /// quadro, ou `null` se nada foi capturado (histórico desligado, app fora do
  /// primeiro plano, captura em andamento ou nada renderizado).
  Future<String?> captureHistoryFrame() async {
    if (historyFrames <= 0 || !isAttached || _capturingHistory || _capturing) return null;
    final lifecycle = SchedulerBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return null;
    _capturingHistory = true;
    try {
      final image = await capture();
      if (image == null) return null;
      final frame = _Frame(_uuid(), DateTime.now(), image);
      _history.add(frame);
      while (_history.length > historyFrames) {
        _history.removeAt(0).image.dispose();
      }
      _logCapture(frame);
      return frame.id;
    } catch (e, s) {
      controller.reportError(e, s, this);
      return null;
    } finally {
      _capturingHistory = false;
    }
  }

  void _logCapture(_Frame frame) {
    unawaited(controller.log(AdaptLogEntry(
      message: 'Capturado quadro da tela - UUID ${frame.id}',
      level: historyLogLevel,
      timestamp: frame.capturedAt,
      metadata: {
        isFrameCaptureKey: true,
        frameIdKey: frame.id,
        frameCapturedAtKey: frame.capturedAt.toUtc().toIso8601String(),
      },
    )));
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
    // O histórico continua girando enquanto os PNGs são gerados: trabalha em
    // cópias, que não são descartadas junto com os quadros antigos.
    final frames = <_Frame>[for (final frame in _history) frame.clone()];
    try {
      final image = await capture();
      if (image != null) {
        final frame = _Frame(_uuid(), DateTime.now(), image, moment: 'error');
        frames.add(frame);
        if (historyFrames > 0) _logCapture(frame);
      }
      if (frames.isEmpty) {
        _skipped++;
        return;
      }
      for (var i = 0; i < frames.length; i++) {
        final frame = frames[i];
        final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) continue;
        final png = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        _captured++;
        await controller.log(AdaptLogEntry(
          message: 'Quadro da tela anexado ao erro - UUID ${frame.id}',
          level: AdaptLogLevel.info,
          timestamp: frame.capturedAt,
          metadata: {
            isScreenshotKey: true,
            screenshotForKey: error.id,
            idKey: frame.id,
            capturedAtKey: frame.capturedAt.toUtc().toIso8601String(),
            indexKey: i + 1,
            countKey: frames.length,
            momentKey: frame.moment,
            formatKey: 'png',
            widthKey: frame.image.width,
            heightKey: frame.image.height,
            screenshotKey: base64Encode(png),
          },
        ));
      }
    } catch (e, s) {
      controller.reportError(e, s, this);
    } finally {
      for (final frame in frames) {
        frame.image.dispose();
      }
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

  static final Random _random = Random.secure();

  /// UUID versão 4 (aleatório), no formato canônico.
  static String _uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Um quadro capturado: a imagem rasterizada (ainda sem PNG), o UUID e a hora.
class _Frame {
  final String id;
  final DateTime capturedAt;
  final ui.Image image;
  final String moment;

  _Frame(this.id, this.capturedAt, this.image, {this.moment = 'history'});

  _Frame clone() => _Frame(id, capturedAt, image.clone(), moment: moment);
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
