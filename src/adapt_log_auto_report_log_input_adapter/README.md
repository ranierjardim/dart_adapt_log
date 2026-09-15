# adapt_log_auto_report_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_auto_report_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_auto_report_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Input adapter que monitora o fluxo de logs e dispara automaticamente um report completo toda vez que uma entrada de nível `error` é detectada, sem necessidade de chamada manual.

> **Atenção:** este adapter é open source, mas depende transitivamente do módulo pago [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) para que os reports sejam transmitidos ao servidor.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_report_log_input_adapter: ^1.0.0
  adapt_log_auto_report_log_input_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_auto_report_log_input_adapter/adapt_log_auto_report_log_input_adapter.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();
final report = ReportLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [
    log,
    report,
    AutoReportLogInputAdapter(reportAdapter: report),
  ],
  outputs: [
    // adapt_log_sqlite_database_output_adapter — buffer local
    // adapt_log_real_time_remote_log_output_adapter (pago) — envio ao servidor
  ],
);
await adaptLog.initialize();

// Nenhuma chamada manual necessária: ao logar um erro, o report é enviado automaticamente
await log.error('Falha crítica no checkout');
```

## Como funciona

`AutoReportLogInputAdapter` sobrescreve `enrichEntry()`. A cada entry que passa pelo pipeline do `AdaptLogController`, verifica se o nível é `error` e se não é um report já emitido (flag `isReport: true`). Ao detectar um erro elegível, dispara `reportAdapter.sendReport()` de forma assíncrona sem bloquear o pipeline.

## API

### `AutoReportLogInputAdapter`

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `reportAdapter` | `ReportLogInputAdapter` | Instância do adapter de report já registrada em `AdaptLog.inputs` |

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `adapt_log_report_log_input_adapter` | Composição e envio do report ao detectar erro |

## Pacotes relacionados

- [`adapt_log_report_log_input_adapter`](../adapt_log_report_log_input_adapter/) — usado internamente; também disponível para reports manuais
- [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) — output necessário para envio ao servidor

## Licença

MIT
