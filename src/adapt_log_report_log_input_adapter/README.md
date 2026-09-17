# adapt_log_report_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_report_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_report_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Input adapter para emissão de reports: entries de nível `info` marcadas com `metadata.isReport` e o contexto informado. O adapter remoto usa essa marcação para montar e transmitir o report ao servidor.

> **Atenção:** este adapter é open source, mas requer o módulo pago `adapt_log_real_time_remote_log_output_adapter` registrado como output para a transmissão ao servidor funcionar.

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
final sent = await report.sendReport(context: 'Tela de pagamento');
```

## API

### `ReportLogInputAdapter`

```dart
Future<bool> sendReport({String? context, Map<String, dynamic>? data})
bool get isSending
```

`sendReport()` emite um `AdaptLogEntry` com `level: info` e metadata `isReport: true`, `reportContext`, `reportTimestamp` e o que vier em `data`. Enquanto um report ainda não foi processado por todos os outputs, novas chamadas são coalescidas: retornam `false` sem emitir nada. Retorna `true` quando o report foi processado.

O flag `isReport` evita loops quando usado com [`adapt_log_auto_report_log_input_adapter`](../adapt_log_auto_report_log_input_adapter/).

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `adapt_log_real_time_remote_log_output_adapter` *(pago)* | Transmissão do report ao servidor |

## Pacotes relacionados

- [`adapt_log_auto_report_log_input_adapter`](../adapt_log_auto_report_log_input_adapter/) — dispara reports automaticamente a cada erro
- `adapt_log_real_time_remote_log_output_adapter` — output necessário para envio ao servidor

## Licença

MIT
