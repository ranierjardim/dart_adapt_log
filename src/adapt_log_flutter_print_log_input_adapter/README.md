# adapt_log_flutter_print_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_flutter_print_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_flutter_print_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Input adapter Flutter que intercepta chamadas de `print()` e `debugPrint()` da aplicação e as redireciona como entradas de log para o ecossistema `adapt_log`. Exclusivo Flutter.

## O que intercepta

| Mecanismo | Captura |
|---|---|
| `debugPrint = ...` | Todas as chamadas a `debugPrint()` |
| `FlutterError.onError` | Erros do framework Flutter (widgets, overflow, assertions) |
| `ZoneSpecification(print:...)` | Chamadas a `print()` dentro da zona da aplicação _(opt-in)_ |

> Para erros Dart assíncronos fora da zona Flutter, use em conjunto com [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/), que cobre `PlatformDispatcher.instance.onError`.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_flutter_print_log_input_adapter: ^1.0.0
```

## Uso básico

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_flutter_print_log_input_adapter/adapt_log_flutter_print_log_input_adapter.dart';

// Inicializar antes de runApp()
final printAdapter = FlutterPrintLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [printAdapter],
  outputs: [/* seu output aqui */],
);
await adaptLog.initialize();

// A partir daqui, todo debugPrint() e FlutterError são capturados
runApp(const MyApp());
```

## Cobertura completa de print() com zona

Para capturar também chamadas diretas a `print()`, envolva o `runApp` em `runZoned` usando o `zoneSpecification` do adapter:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final printAdapter = FlutterPrintLogInputAdapter();
  final adaptLog = AdaptLog(
    inputs: [printAdapter],
    outputs: [/* seu output aqui */],
  );
  await adaptLog.initialize();

  runZoned(
    () => runApp(const MyApp()),
    zoneSpecification: printAdapter.zoneSpecification,
  );
}
```

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `flutter` | APIs `debugPrint` e `FlutterError` |

## Pacotes relacionados

- [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/) — cobre `PlatformDispatcher.instance.onError`
- [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/) — persiste os prints capturados

## Licença

MIT
