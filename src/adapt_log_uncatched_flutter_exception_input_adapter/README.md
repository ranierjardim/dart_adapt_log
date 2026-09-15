# adapt_log_uncatched_flutter_exception_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_uncatched_flutter_exception_input_adapter.svg)](https://pub.dev/packages/adapt_log_uncatched_flutter_exception_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Input adapter Flutter que captura automaticamente todas as exceções não tratadas da aplicação e as registra como entradas de erro no ecossistema `adapt_log`. Exclusivo Flutter.

## O que captura

| Hook | Origem |
|---|---|
| `FlutterError.onError` | Erros do framework Flutter (widgets, overflow, assertions) |
| `PlatformDispatcher.instance.onError` | Erros Dart assíncronos fora da zona Flutter |

Não captura logs nativos do SO — para isso use [`adapt_log_native_log_input_adapter`](../adapt_log_native_log_input_adapter/).

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_uncatched_flutter_exception_input_adapter: ^1.0.0
```

## Uso

Deve ser inicializado **antes** de `runApp()`, de preferência dentro de `runZonedGuarded()`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_uncatched_flutter_exception_input_adapter/adapt_log_uncatched_flutter_exception_input_adapter.dart';
import 'package:adapt_log_sqlite_database_output_adapter/adapt_log_sqlite_database_output_adapter.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final exceptionAdapter = UncatchedFlutterExceptionInputAdapter();
    final db = SqliteDatabaseOutputAdapter();

    final adaptLog = AdaptLog(
      inputs: [exceptionAdapter],
      outputs: [db],
    );
    await adaptLog.initialize();

    runApp(const MyApp());
  }, (error, stack) {
    // Erros de zona são capturados automaticamente pelo adapter
  });
}
```

## Cobertura combinada

Para cobertura completa de todos os tipos de output:

```dart
inputs: [
  UncatchedFlutterExceptionInputAdapter(), // exceções não tratadas
  FlutterPrintLogInputAdapter(),           // print() e debugPrint()
  NativeLogInputAdapter(),                 // logs nativos do SO
  TextLogInputAdapter(),                   // logs manuais
]
```

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `adapt_log_text_log_input_adapter` | Formatação textual das exceções capturadas |
| `flutter` | `FlutterError`, `PlatformDispatcher` |

## Pacotes relacionados

- [`adapt_log_flutter_print_log_input_adapter`](../adapt_log_flutter_print_log_input_adapter/) — captura `print()` e erros de framework
- [`adapt_log_native_log_input_adapter`](../adapt_log_native_log_input_adapter/) — logs nativos do SO
- [`adapt_log_auto_report_log_input_adapter`](../adapt_log_auto_report_log_input_adapter/) — dispara report automático a cada erro capturado

## Licença

MIT
