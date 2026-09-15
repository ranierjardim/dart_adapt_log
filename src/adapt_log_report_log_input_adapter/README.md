# adapt_log_report_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_report_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_report_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Input adapter para envio manual de reports completos ao servidor. Agrega logs textuais, prints e metadados de contexto em um único payload estruturado.

> **Atenção:** este adapter é open source, mas requer o módulo pago [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) registrado como output para a transmissão ao servidor funcionar.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_report_log_input_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_report_log_input_adapter/adapt_log_report_log_input_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();
final report = ReportLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [log, report],
  outputs: [
    // adapt_log_real_time_remote_log_output_adapter (pago) para envio ao servidor
    // adapt_log_sqlite_database_output_adapter para buffer local
  ],
);
await adaptLog.initialize();

// Uso normal
await log.warning('Tentativa de login inválida');

// Disparar report manual em situações críticas
await report.sendReport(context: 'Tela de pagamento');
```

## API

### `ReportLogInputAdapter`

```dart
Future<void> sendReport({String? context})
```

Gera um `AdaptLogEntry` com `level: info`, `metadata.isReport: true` e o contexto fornecido. O flag `isReport` evita loops quando usado com [`adapt_log_auto_report_log_input_adapter`](../adapt_log_auto_report_log_input_adapter/).

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `adapt_log_text_log_input_adapter` | Entrada textual que compõe o report |
| `adapt_log_real_time_remote_log_output_adapter` *(pago)* | Transmissão do report ao servidor |

## Pacotes relacionados

- [`adapt_log_auto_report_log_input_adapter`](../adapt_log_auto_report_log_input_adapter/) — dispara reports automaticamente a cada erro
- [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) — output necessário para envio ao servidor

## Licença

MIT
