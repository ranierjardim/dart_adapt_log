# adapt_log_sqlite_database_output_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_sqlite_database_output_adapter.svg)](https://pub.dev/packages/adapt_log_sqlite_database_output_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Output adapter que persiste os logs recebidos em um banco SQLite local, com retenção configurável, permitindo consulta e filtragem posterior. Também serve como buffer local para o [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/).

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_sqlite_database_output_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_sqlite_database_output_adapter/adapt_log_sqlite_database_output_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();
final db = SqliteDatabaseOutputAdapter(dbName: 'meuapp_logs.db', maxEntries: 5000);

final adaptLog = AdaptLog(
  inputs: [log],
  outputs: [db],
);
await adaptLog.initialize();

await log.info('Pedido #1234 criado');
await log.error('Pagamento recusado');

// Consultar logs armazenados
final erros = await db.getLogs(level: AdaptLogLevel.error, limit: 50);
```

## API

### `SqliteDatabaseOutputAdapter`

| Parâmetro | Tipo | Padrão | Descrição |
|---|---|---|---|
| `dbName` | `String` | `adapt_log.db` | Nome do arquivo dentro de `getDatabasesPath()` |
| `path` | `String?` | — | Caminho completo do arquivo; se informado, `dbName` é ignorado |
| `maxEntries` | `int?` | `10000` | Máximo de entries mantidas; as mais antigas são removidas. `null` desativa |
| `pruneInterval` | `int` | `100` | A poda roda a cada N inserções e em `initialize()` |

### Métodos de consulta

```dart
// Retorna logs das mais recentes para as mais antigas
Future<List<AdaptLogEntry>> getLogs({int? limit, AdaptLogLevel? level});

Future<int> count();

// Remove todos os logs
Future<void> clearLogs();
```

`metadata` é gravada como JSON; valores não serializáveis viram `toString()`.

## Schema do banco

```sql
CREATE TABLE logs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id    TEXT    NOT NULL UNIQUE,
  message     TEXT    NOT NULL,
  level       TEXT    NOT NULL,
  timestamp   TEXT    NOT NULL,   -- UTC
  error       TEXT,
  error_type  TEXT,
  stack_trace TEXT,
  metadata    TEXT               -- JSON
);
CREATE INDEX idx_logs_level ON logs(level);
CREATE INDEX idx_logs_timestamp ON logs(timestamp);
```

## Testes

Em testes, use `sqflite_common_ffi` e `path: inMemoryDatabasePath` para um banco em memória sem plugin.

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogOutput` |
| `sqflite` | Driver SQLite para Flutter |
| `path` | Resolução do caminho do arquivo de banco |

## Pacotes relacionados

- [`adapt_log`](../adapt_log/) — core do ecossistema
- [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) — usa este adapter como buffer para envio ao servidor
- [`adapt_log_device_app_info_input_adapter`](../adapt_log_device_app_info_input_adapter/) — enriquece os metadados salvos no banco

## Licença

MIT
