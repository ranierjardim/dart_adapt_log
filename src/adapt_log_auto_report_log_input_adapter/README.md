# adapt_log_auto_report_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_auto_report_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_auto_report_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Input adapter que observa o pipeline e dispara automaticamente um report toda vez que uma entry de nível `error` é detectada, sem necessidade de chamada manual.

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

`AutoReportLogInputAdapter` sobrescreve `enrichEntry()`. A cada entry que passa pelo pipeline, verifica se o nível é `error` e se não é um report (flag `isReport: true`). Ao detectar um erro elegível, chama `reportAdapter.sendReport()` com o contexto de `buildReportContext(entry)`.

- O report entra na fila do core e chega aos outputs **depois** da entry de erro que o disparou, com `metadata.reportFor` igual ao `id` dela.
- Se `reportAdapter` não estiver registrado em `AdaptLog.inputs`, a falha é reportada em `AdaptLog.onError` e a entry de erro segue normalmente.
- Reports disparados enquanto outro ainda está em andamento são coalescidos (ver `ReportLogInputAdapter.sendReport`).

## API

### `AutoReportLogInputAdapter`

| Membro | Descrição |
|---|---|
| `reportAdapter` | Instância de `ReportLogInputAdapter` já registrada em `AdaptLog.inputs` |
| `buildReportContext(entry)` | Monta o contexto do report; sobrescreva para acrescentar informações. Padrão: `entry.message` |

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `adapt_log_report_log_input_adapter` | Emissão do report ao detectar erro |

## Pacotes relacionados

- [`adapt_log_report_log_input_adapter`](../adapt_log_report_log_input_adapter/) — usado internamente; também disponível para reports manuais
- [`adapt_log_flutter_auto_report_log_input_adapter`](../adapt_log_flutter_auto_report_log_input_adapter/) — versão Flutter que anexa os últimos `debugPrint` ao report
- [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) — output necessário para envio ao servidor

## Licença

MIT
