# adapt_log_logger_print_package_output_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_logger_print_package_output_adapter.svg)](https://pub.dev/packages/adapt_log_logger_print_package_output_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Output adapter que exibe logs no console com formatação rica, com cores por nível, timestamp e stack trace, usando o package [`logger`](https://pub.dev/packages/logger).

Indicado para desenvolvimento e debug. Não persiste logs.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_logger_print_package_output_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_logger_print_package_output_adapter/adapt_log_logger_print_package_output_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [log],
  outputs: [
    LoggerPrintOutputAdapter(
      level: Level.debug, // nível mínimo exibido
    ),
  ],
);
await adaptLog.initialize();

await log.info('Servidor iniciado na porta 8080');
await log.error('Conexão recusada', stackTrace: StackTrace.current);
```

## API

### `LoggerPrintOutputAdapter`

| Parâmetro | Tipo | Padrão | Descrição |
|---|---|---|---|
| `level` | `Level` | `Level.trace` | Nível mínimo a ser exibido (escala do package `logger`) |
| `dateTimeFormat` | `DateTimeFormatter` | `DateTimeFormat.onlyTimeAndSinceStart` | Formato do timestamp; `DateTimeFormat.none` omite |
| `stackTraceMethodCount` | `int` | `8` | Frames impressos do stack trace da entry |
| `output` | `LogOutput?` | console | Destino das linhas (útil em testes, com `MemoryOutput`) |
| `filter` | `LogFilter?` | `ProductionFilter()` | Imprime em qualquer modo de execução, respeitando `level`. O `DevelopmentFilter` do `logger` só imprime com asserts habilitados |

Entries sem stack trace não imprimem frame nenhum: o stack "atual" nesse ponto só teria frames internos do pipeline.

### Mapeamento de níveis

| `AdaptLogLevel` | Nível `logger` |
|---|---|
| `debug` | `Logger.d()` |
| `info` | `Logger.i()` |
| `warning` | `Logger.w()` |
| `error` | `Logger.e()` |

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogOutput` |
| `logger` (`^2.4.0`) | PrettyPrinter para formatação colorida no console |

## Pacotes relacionados

- [`adapt_log`](../adapt_log/) — core do ecossistema
- [`adapt_log_text_log_input_adapter`](../adapt_log_text_log_input_adapter/) — input textual compatível
- [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/) — persistência local em SQLite

## Licença

MIT
