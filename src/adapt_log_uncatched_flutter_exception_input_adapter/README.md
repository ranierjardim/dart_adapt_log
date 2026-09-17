# adapt_log_uncatched_flutter_exception_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_uncatched_flutter_exception_input_adapter.svg)](https://pub.dev/packages/adapt_log_uncatched_flutter_exception_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Input adapter Flutter que captura exceções não tratadas da aplicação e as registra como entries de nível `error`, com a exceção original em `entry.error` e o stack trace. Exclusivo Flutter.

## O que captura

| Hook | Origem | `metadata['source']` |
|---|---|---|
| `FlutterError.onError` | Erros do framework (widgets, overflow, assertions) | `FlutterError` |
| `PlatformDispatcher.instance.onError` | Erros Dart assíncronos não tratados no isolate raiz (Flutter 3.3+) | `PlatformDispatcher` |
| `handleUncaughtError()` | Erros encaminhados manualmente, por exemplo de `runZonedGuarded` | `zone` |

Os handlers anteriores continuam sendo chamados depois do registro, então o comportamento padrão, como imprimir o erro no console, é preservado. `AdaptLog.shutdown()` restaura os hooks, a menos que outro tenha sido instalado por cima.

Não captura logs nativos do SO; para isso use [`adapt_log_native_log_input_adapter`](../adapt_log_native_log_input_adapter/).

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_uncatched_flutter_exception_input_adapter: ^1.0.0
```

## Uso

Inicialize **antes** de `runApp()`:

```dart
import 'package:flutter/material.dart';
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_uncatched_flutter_exception_input_adapter/adapt_log_uncatched_flutter_exception_input_adapter.dart';
import 'package:adapt_log_sqlite_database_output_adapter/adapt_log_sqlite_database_output_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final adaptLog = AdaptLog(
    inputs: [UncatchedFlutterExceptionInputAdapter()],
    outputs: [SqliteDatabaseOutputAdapter()],
  );
  await adaptLog.initialize();

  runApp(const MyApp());
}
```

### Se a app já usa `runZonedGuarded`

Erros capturados por `runZonedGuarded` **nunca chegam** a `PlatformDispatcher.onError`. Não envolva a app em `runZonedGuarded` só por causa deste adapter; se ela já usa, encaminhe pelo handler:

```dart
final adapter = UncatchedFlutterExceptionInputAdapter();
// ... registrar em AdaptLog e aguardar initialize()

runZonedGuarded(() => runApp(const MyApp()), adapter.handleUncaughtError);
```

Antes de `initialize()`, `handleUncaughtError` encaminha o erro a `FlutterError.reportError` para que ele não se perca.

## Cobertura combinada

```dart
inputs: [
  UncatchedFlutterExceptionInputAdapter(), // exceções não tratadas
  FlutterPrintLogInputAdapter(),           // print() e debugPrint()
  TextLogInputAdapter(),                   // logs manuais
]
```

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `flutter` | `FlutterError`, `PlatformDispatcher` |

## Pacotes relacionados

- [`adapt_log_flutter_print_log_input_adapter`](../adapt_log_flutter_print_log_input_adapter/) — captura `print()` e `debugPrint()`
- [`adapt_log_native_log_input_adapter`](../adapt_log_native_log_input_adapter/) — logs nativos do SO
- [`adapt_log_auto_report_log_input_adapter`](../adapt_log_auto_report_log_input_adapter/) — dispara report automático a cada erro capturado

## Licença

MIT
