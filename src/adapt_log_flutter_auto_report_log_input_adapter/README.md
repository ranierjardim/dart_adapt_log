# adapt_log_flutter_auto_report_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_flutter_auto_report_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_flutter_auto_report_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Versão Flutter do [`adapt_log_auto_report_log_input_adapter`](../adapt_log_auto_report_log_input_adapter/): guarda as últimas linhas impressas via `debugPrint`, anexa-as a cada entry de nível `error` em `metadata['recentPrints']` e ao contexto do report disparado. É isso que o painel do `adapt_log_server` mostra como "Prints antes do erro". Exclusivo Flutter.

> **Atenção:** depende transitivamente do módulo pago [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) para que os reports sejam transmitidos ao servidor.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_report_log_input_adapter: ^1.0.0
  adapt_log_flutter_auto_report_log_input_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_auto_report_log_input_adapter/adapt_log_flutter_auto_report_log_input_adapter.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();
final report = ReportLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [
    log,
    report,
    FlutterAutoReportLogInputAdapter(reportAdapter: report, maxPrintBuffer: 50),
  ],
  outputs: [/* buffer local + adapter remoto (pago) */],
);
await adaptLog.initialize();

debugPrint('abrindo tela de pagamento');
await log.error('Falha crítica no checkout');
// Report: "Falha crítica no checkout" + as últimas linhas de debugPrint
```

## Como funciona

Estende `AutoReportLogInputAdapter`: sobrescreve `enrichEntry()` para anexar o buffer circular de `debugPrint` à entry de erro e `buildReportContext()` para repeti-lo no report. O hook de `debugPrint` chama a implementação anterior, então a saída no console é preservada; `AdaptLog.shutdown()` restaura o hook e limpa o buffer.

## API

### `FlutterAutoReportLogInputAdapter`

| Membro | Padrão | Descrição |
|---|---|---|
| `reportAdapter` | — | Instância de `ReportLogInputAdapter` registrada em `AdaptLog.inputs` |
| `maxPrintBuffer` | `50` | Linhas de `debugPrint` mantidas no buffer circular |
| `recentPrints` | — | Linhas atualmente no buffer |

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `adapt_log_auto_report_log_input_adapter` | Lógica de disparo do report |
| `adapt_log_report_log_input_adapter` | Emissão do report |
| `flutter` | API `debugPrint` |

## Licença

MIT
