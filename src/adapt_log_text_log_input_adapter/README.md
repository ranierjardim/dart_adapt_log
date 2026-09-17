# adapt_log_text_log_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_text_log_input_adapter.svg)](https://pub.dev/packages/adapt_log_text_log_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Input adapter para emissão de logs textuais em qualquer aplicação Dart ou Flutter. Expõe uma API simples com os quatro níveis de log: `debug`, `info`, `warning` e `error`.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_text_log_input_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [log],
  outputs: [/* seu output aqui */],
);
await adaptLog.initialize();

await log.debug('Payload recebido', metadata: {'bytes': payload.length});
await log.info('Usuário autenticado');
await log.warning('Token próximo do vencimento');
await log.error('Falha ao conectar', error: e, stackTrace: st);
```

Os métodos retornam um `Future` que completa quando todos os outputs processaram a entry. Aguardá-lo é opcional; eles nunca lançam por falha de output.

## API

### `TextLogInputAdapter`

| Método | Nível | Descrição |
|---|---|---|
| `debug(message, {metadata})` | `AdaptLogLevel.debug` | Informação de diagnóstico detalhado |
| `info(message, {metadata})` | `AdaptLogLevel.info` | Evento normal do fluxo da aplicação |
| `warning(message, {error, stackTrace, metadata})` | `AdaptLogLevel.warning` | Situação anormal mas recuperável |
| `error(message, {error, stackTrace, metadata})` | `AdaptLogLevel.error` | Erro que requer atenção |

`error` recebe a exceção original; ela segue para os outputs como objeto e é serializada como texto e tipo.

Chamar qualquer método antes de `AdaptLog.initialize()` lança `StateError`.

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` e `AdaptLogController` |

## Pacotes relacionados

- [`adapt_log`](../adapt_log/) — core do ecossistema
- [`adapt_log_logger_print_package_output_adapter`](../adapt_log_logger_print_package_output_adapter/) — exibe os logs no console
- [`adapt_log_uncatched_flutter_exception_input_adapter`](../adapt_log_uncatched_flutter_exception_input_adapter/) — captura exceções não tratadas

## Licença

MIT
