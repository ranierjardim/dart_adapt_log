# adapt_log_flutter_print_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_flutter_print_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_flutter_print_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Input adapter Flutter que intercepta chamadas de `debugPrint()` e, opcionalmente, `print()` e as emite como entries de nível `debug`. Exclusivo Flutter.

## O que intercepta

| Mecanismo | Captura |
|---|---|
| `debugPrint = ...` | Todas as chamadas a `debugPrint()` |
| `ZoneSpecification(print: ...)` | Chamadas a `print()` dentro da zona da aplicação _(opt-in)_ |

- A saída original é preservada: o hook chama o `debugPrint` anterior e a zona delega ao `print` da zona pai.
- Um `debugPrint()` dentro da zona gera **uma** entry, não duas.
- Outputs que imprimem no console durante o despacho (como o adapter do package `logger`) não geram novas entries: o core descarta `log()` re-entrante, então não há loop.

> Erros do framework e exceções não tratadas não são tratados aqui. Use [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/).

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

// A partir daqui, todo debugPrint() é capturado
runApp(const MyApp());
```

## Cobertura de print() com zona

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

`AdaptLog.shutdown()` restaura o `debugPrint` anterior, a menos que outro hook tenha sido instalado por cima.

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `flutter` | API `debugPrint` |

## Pacotes relacionados

- [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/) — erros do framework e exceções não tratadas
- [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/) — persiste os prints capturados

## Licença

MIT
