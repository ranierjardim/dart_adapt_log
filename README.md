# dart_adapt_log

Ecossistema de logging para Dart e Flutter baseado no padrão **Ports & Adapters**. O sistema que consome o pacote define quais entradas e saídas de log utiliza, sem acoplamento entre elas.

## Módulos

### Open Source

| Pacote | Tipo | Descrição |
|---|---|---|
| [`adapt_log`](src/adapt_log/) | Core | Contratos, orquestração e garantias do pipeline |
| [`adapt_log_text_log_input_adapter`](src/adapt_log_text_log_input_adapter/) | Input | Emissão de logs textuais: `debug`, `info`, `warning`, `error` |
| [`adapt_log_device_app_info_input_adapter`](src/adapt_log_device_app_info_input_adapter/) | Input | Enriquece logs com informações do dispositivo e do app _(Flutter)_ |
| [`adapt_log_flutter_print_log_input_adapter`](src/adapt_log_flutter_print_log_input_adapter/) | Input | Intercepta `print()` e `debugPrint()` _(Flutter)_ |
| [`adapt_log_native_log_input_adapter`](src/adapt_log_native_log_input_adapter/) | Input | Logs nativos do SO (Android Logcat / iOS os_log). Ponte nativa pendente |
| [`adapt_log_report_log_input_adapter`](src/adapt_log_report_log_input_adapter/) | Input | Emite reports para o servidor (requer módulo pago) |
| [`adapt_log_auto_report_log_input_adapter`](src/adapt_log_auto_report_log_input_adapter/) | Input | Dispara um report automaticamente a cada erro |
| [`adapt_log_flutter_auto_report_log_input_adapter`](src/adapt_log_flutter_auto_report_log_input_adapter/) | Input | Auto report com as últimas linhas de `debugPrint` _(Flutter)_ |
| [`adapt_log_uncatched_flutter_exception_input_adapter`](src/adapt_log_uncatched_flutter_exception_input_adapter/) | Input | Captura exceções não tratadas _(Flutter)_ |
| [`adapt_log_flutter_error_screenshot_input_adapter`](src/adapt_log_flutter_error_screenshot_input_adapter/) | Input | Captura a tela quando um erro é logado _(Flutter)_ |
| [`adapt_log_logger_print_package_output_adapter`](src/adapt_log_logger_print_package_output_adapter/) | Output | Exibe logs formatados (PrettyPrint) via package `logger` |
| [`adapt_log_sqlite_database_output_adapter`](src/adapt_log_sqlite_database_output_adapter/) | Output | Persiste logs em SQLite local, com retenção _(Flutter)_ |
| [`adapt_log_remote_protocol`](src/adapt_log_remote_protocol/) | Contrato | Formato JSON de lotes, sessões e eventos entre cliente e servidor |

### Closed Source / Pago

Ficam no repositório privado `dart_adapt_log_closed_source`, disponível via assinatura.

| Pacote | Tipo | Descrição |
|---|---|---|
| `adapt_log_real_time_remote_log_output_adapter` | Output | Transmite logs ao servidor em lotes, com reenvio |
| `adapt_log_server` | Servidor | Recebe, persiste em SQLite e serve logs; painel web embutido |

## Dependências entre módulos

```
adapt_log  (core)
├── adapt_log_text_log_input_adapter
├── adapt_log_report_log_input_adapter
│   └── adapt_log_auto_report_log_input_adapter
│       └── adapt_log_flutter_auto_report_log_input_adapter        [Flutter]
├── adapt_log_uncatched_flutter_exception_input_adapter            [Flutter]
├── adapt_log_flutter_error_screenshot_input_adapter               [Flutter]
├── adapt_log_device_app_info_input_adapter                        [Flutter]
├── adapt_log_flutter_print_log_input_adapter                      [Flutter]
├── adapt_log_native_log_input_adapter
├── adapt_log_logger_print_package_output_adapter
├── adapt_log_sqlite_database_output_adapter                       [Flutter]
└── adapt_log_remote_protocol
    ├── adapt_log_real_time_remote_log_output_adapter  ← PAGO, repositório privado
    └── adapt_log_server                               ← PAGO, repositório privado
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

await adaptLog.shutdown();
```

## Do erro ao painel

No app Flutter, registre os adapters de captura e o adapter remoto. O adapter remoto e o servidor são pagos e ficam no repositório privado `dart_adapt_log_closed_source`.

```dart
final log = TextLogInputAdapter();
final report = ReportLogInputAdapter();
final screenshot = FlutterErrorScreenshotInputAdapter();

final adaptLog = AdaptLog(
  inputs: [
    DeviceAppInfoInputAdapter(),
    UncatchedFlutterExceptionInputAdapter(),
    log,
    report,
    FlutterAutoReportLogInputAdapter(reportAdapter: report), // guarda os últimos debugPrint
    screenshot,                                              // captura a tela a cada erro
  ],
  outputs: [
    RealTimeRemoteLogOutputAdapter(serverUrl: 'https://logs.meuapp.com', apiKey: 'SUA_CHAVE'),
  ],
);
await adaptLog.initialize();
runApp(AdaptLogScreenshotBoundary(adapter: screenshot, child: const MyApp()));
```

Suba o servidor, a partir do repositório privado, e abra o painel:

```sh
cd src/adapt_log_server
ADAPT_LOG_API_KEYS="SUA_CHAVE:meu-app" dart run bin/adapt_log_server.dart
# painel em http://localhost:8080
```

Cada erro chega ao painel com tipo e mensagem da exceção, stack trace, a tela no momento do erro, os últimos `debugPrint` antes dele, o report disparado automaticamente e a metadata do dispositivo e do app.

## Garantias do pipeline

- Logar nunca lança por falha de adapter: exceções de `enrichEntry()`, `onNewLog()`, `initialize()` e `shutdown()` são isoladas e entregues a `AdaptLog.onError`.
- Cada output recebe as entries na ordem em que foram logadas; outputs diferentes não bloqueiam uns aos outros.
- Uma entry emitida de dentro de um output (por exemplo um `print()` interceptado) é descartada, o que evita recursão infinita.
- `initialize()` e `shutdown()` são idempotentes. Logar antes de `initialize()` lança `StateError`; depois de `shutdown()` a entry é descartada.

Detalhes em [`adapt_log`](src/adapt_log/).

## Desenvolvimento

```sh
make pubget    # pub get em todos os pacotes
make analyze   # dart/flutter analyze em todos os pacotes
make test      # dart/flutter test em todos os pacotes
```

Os pacotes Flutter exigem Dart 3.3+ e Flutter 3.19+ por causa de `device_info_plus` e `package_info_plus`. Os pacotes Dart puro funcionam a partir do Dart 3.0 (testados em 3.2 e 3.12).

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
  adapt_log_flutter_auto_report_log_input_adapter/
  adapt_log_uncatched_flutter_exception_input_adapter/
  adapt_log_flutter_error_screenshot_input_adapter/
  adapt_log_logger_print_package_output_adapter/
  adapt_log_sqlite_database_output_adapter/
  adapt_log_remote_protocol/
```

## Licença

MIT, para todos os pacotes deste repositório. O adapter remoto e o servidor são proprietários e ficam no repositório privado `dart_adapt_log_closed_source`.
