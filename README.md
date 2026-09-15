# dart_adapt_log

Ecossistema de logging para Dart e Flutter baseado no padrão **Ports & Adapters**. O sistema que consome o pacote define quais entradas e saídas de log utiliza — sem acoplamento entre eles.

## Módulos

### Open Source

| Pacote | Tipo | Descrição |
|---|---|---|
| [`adapt_log`](src/adapt_log/) | Core | Contratos e orquestração central do ecossistema |
| [`adapt_log_text_log_input_adapter`](src/adapt_log_text_log_input_adapter/) | Input | Emissão de logs textuais: `info`, `warning`, `error`, `debug` |
| [`adapt_log_device_app_info_input_adapter`](src/adapt_log_device_app_info_input_adapter/) | Input | Enriquece logs com informações do dispositivo e do app _(Flutter)_ |
| [`adapt_log_flutter_print_log_input_adapter`](src/adapt_log_flutter_print_log_input_adapter/) | Input | Intercepta `print()` e `debugPrint()` _(Flutter)_ |
| [`adapt_log_native_log_input_adapter`](src/adapt_log_native_log_input_adapter/) | Input | Captura erros nativos do SO (Android Logcat / iOS NSLog) |
| [`adapt_log_report_log_input_adapter`](src/adapt_log_report_log_input_adapter/) | Input | Envia reports completos ao servidor (requer módulo pago) |
| [`adapt_log_auto_report_log_input_adapter`](src/adapt_log_auto_report_log_input_adapter/) | Input | Dispara report automático a cada erro detectado |
| [`adapt_log_uncatched_flutter_exception_input_adapter`](src/adapt_log_uncatched_flutter_exception_input_adapter/) | Input | Captura exceções não tratadas no Flutter _(Flutter)_ |
| [`adapt_log_logger_print_package_output_adapter`](src/adapt_log_logger_print_package_output_adapter/) | Output | Exibe logs formatados (PrettyPrint) via package `logger` |
| [`adapt_log_sqlite_database_output_adapter`](src/adapt_log_sqlite_database_output_adapter/) | Output | Persiste logs em SQLite local _(Flutter)_ |

### Closed Source / Pago

| Pacote | Tipo | Descrição |
|---|---|---|
| [`adapt_log_real_time_remote_log_output_adapter`](src/adapt_log_real_time_remote_log_output_adapter/) | Output | Transmite logs ao servidor em tempo real |
| [`adapt_log_server`](src/adapt_log_server/) | Servidor | Recebe e serve logs; base do painel web |

## Dependências entre módulos

```
adapt_log  (core)
├── adapt_log_text_log_input_adapter
│   ├── adapt_log_report_log_input_adapter
│   │   └── adapt_log_auto_report_log_input_adapter
│   └── adapt_log_uncatched_flutter_exception_input_adapter  [Flutter]
├── adapt_log_device_app_info_input_adapter                  [Flutter]
├── adapt_log_flutter_print_log_input_adapter                [Flutter]
├── adapt_log_native_log_input_adapter
├── adapt_log_logger_print_package_output_adapter
└── adapt_log_sqlite_database_output_adapter                 [Flutter]
    ├── adapt_log_real_time_remote_log_output_adapter  ← PAGO
    └── adapt_log_server                               ← PAGO
```

## Exemplo mínimo

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';
import 'package:adapt_log_logger_print_package_output_adapter/adapt_log_logger_print_package_output_adapter.dart';

final log = TextLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [log],
  outputs: [LoggerPrintOutputAdapter()],
);

await adaptLog.initialize();

await log.info('Aplicação iniciada');
await log.error('Algo deu errado', stackTrace: StackTrace.current);
```

## Estrutura do repositório

```
src/
  adapt_log/                                    # core
  adapt_log_text_log_input_adapter/
  adapt_log_device_app_info_input_adapter/
  adapt_log_flutter_print_log_input_adapter/
  adapt_log_native_log_input_adapter/
  adapt_log_report_log_input_adapter/
  adapt_log_auto_report_log_input_adapter/
  adapt_log_uncatched_flutter_exception_input_adapter/
  adapt_log_logger_print_package_output_adapter/
  adapt_log_sqlite_database_output_adapter/
  adapt_log_real_time_remote_log_output_adapter/  # closed source
  adapt_log_server/                               # closed source
```

## Licença

Open Source — MIT. Os módulos `adapt_log_real_time_remote_log_output_adapter` e `adapt_log_server` são Closed Source e disponibilizados via assinatura.
