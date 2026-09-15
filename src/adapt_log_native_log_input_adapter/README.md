# adapt_log_native_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_native_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_native_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Input adapter que captura erros e logs gerados pela camada nativa do sistema operacional (Android Logcat, iOS NSLog/os_log) e os traz para o ecossistema `adapt_log`.

Não captura exceções Dart/Flutter — para isso use [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/).

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

## Status da implementação

A integração com as APIs nativas de cada plataforma (Android `Logcat` via `MethodChannel`/`EventChannel`, iOS `os_log` via `MethodChannel`) está planejada para uma versão futura. A estrutura do adapter está disponível e funcional — a ponte nativa será adicionada sem quebra de API.

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |

## Pacotes relacionados

- [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/) — exceções não tratadas Dart/Flutter
- [`adapt_log_flutter_print_log_input_adapter`](../adapt_log_flutter_print_log_input_adapter/) — `print()` e `debugPrint()` do Flutter

## Licença

MIT
