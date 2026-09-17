# adapt_log_native_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_native_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_native_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Input adapter para logs gerados pela camada nativa do sistema operacional (Android Logcat, iOS os_log/NSLog).

> **Status:** a ponte nativa (`MethodChannel`/`EventChannel`) ainda não foi implementada. Hoje o adapter inicializa e encerra normalmente, mas **não emite nenhuma entry**. A API pública será mantida quando a ponte for adicionada.

Não captura exceções Dart/Flutter; para isso use [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/).

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_native_log_input_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_native_log_input_adapter/adapt_log_native_log_input_adapter.dart';

final adaptLog = AdaptLog(
  inputs: [NativeLogInputAdapter()],
  outputs: [/* seu output aqui */],
);
await adaptLog.initialize();
```

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |

## Pacotes relacionados

- [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/) — exceções não tratadas Dart/Flutter
- [`adapt_log_flutter_print_log_input_adapter`](../adapt_log_flutter_print_log_input_adapter/) — `print()` e `debugPrint()` do Flutter

## Licença

MIT
