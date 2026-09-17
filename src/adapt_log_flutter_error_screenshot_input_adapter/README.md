# adapt_log_flutter_error_screenshot_input_adapter

[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Input adapter Flutter que captura a tela toda vez que uma entry de nível `error` passa pelo pipeline e a emite como uma entry própria, ligada ao erro. Com o adapter remoto, a imagem chega ao `adapt_log_server` e o painel a mostra como **"Tela no momento do erro"**. Exclusivo Flutter.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_flutter_error_screenshot_input_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_error_screenshot_input_adapter/adapt_log_flutter_error_screenshot_input_adapter.dart';

final screenshot = FlutterErrorScreenshotInputAdapter();

final adaptLog = AdaptLog(
  inputs: [
    UncatchedFlutterExceptionInputAdapter(),
    screenshot,
  ],
  outputs: [/* adapter remoto (pago), SQLite... */],
);
await adaptLog.initialize();

// Delimita a área capturada. Sem isso, a raiz da renderização é usada.
runApp(AdaptLogScreenshotBoundary(adapter: screenshot, child: const MyApp()));
```

## Como funciona

1. `enrichEntry()` detecta uma entry `error` que não é report nem screenshot.
2. Se um frame estiver em andamento, espera ele terminar, para que um erro de build seja capturado com a tela como ficou.
3. Renderiza o `RepaintBoundary` de `AdaptLogScreenshotBoundary`, ou a raiz da renderização, em PNG.
4. Emite uma entry `info` com a metadata abaixo. Ela entra na fila depois do erro e chega aos outputs na ordem.

| Chave da metadata | Conteúdo |
|---|---|
| `isScreenshot` | `true` |
| `screenshotFor` | `id` da entry de erro |
| `screenshot` | PNG em base64 |
| `screenshotFormat` | `png` |
| `screenshotWidth`, `screenshotHeight` | Dimensões em pixels |

O servidor extrai a imagem para uma tabela própria, remove o base64 da metadata, marca a entry de erro com `hasScreenshot: true` e serve o PNG em `GET /v1/logs/<id>/screenshot`, tanto pelo id do erro quanto pelo id da screenshot.

## API

### `FlutterErrorScreenshotInputAdapter`

| Parâmetro | Padrão | Descrição |
|---|---|---|
| `pixelRatio` | `1.0` | Pixels da imagem por pixel lógico. `0.5` gera um PNG com um quarto do tamanho |
| `minInterval` | `2s` | Erros dentro do intervalo não geram nova captura |

Leituras: `capturedScreenshots`, `skippedScreenshots`, `capture()` para capturar sob demanda.

### `AdaptLogScreenshotBoundary`

Widget que envolve a app num `RepaintBoundary` com a chave do adapter.

## Limites

- Captura o que o Flutter renderiza; platform views nativas, como mapas e WebViews, aparecem em branco.
- Um PNG de tela inteira em `pixelRatio: 1.0` costuma ter entre 100 KB e 500 KB. O adapter remoto respeita `maxBatchBytes` ao montar os lotes.
- Dados sensíveis na tela vão junto. Combine com cuidado com telas de senha e pagamento.

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `flutter` | `RepaintBoundary`, `RendererBinding`, `SchedulerBinding` |

## Pacotes relacionados

- [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/) — origem das entries de erro não tratadas
- [`adapt_log_flutter_auto_report_log_input_adapter`](../adapt_log_flutter_auto_report_log_input_adapter/) — anexa os últimos `debugPrint` ao erro
- `adapt_log_real_time_remote_log_output_adapter` — envia tudo ao servidor

## Licença

MIT
