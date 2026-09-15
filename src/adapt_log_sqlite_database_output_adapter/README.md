# adapt_log_sqlite_database_output_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_sqlite_database_output_adapter.svg)](https://pub.dev/packages/adapt_log_sqlite_database_output_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Output adapter que persiste todos os logs recebidos em um banco de dados SQLite local, permitindo consulta, filtragem e reutilização posterior. Também serve como buffer local para o [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/).

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
final db = SqliteDatabaseOutputAdapter(dbName: 'meuapp_logs.db');

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
| `dbName` | `String` | `adapt_log.db` | Nome do arquivo SQLite |

### Métodos de consulta

```dart
// Retorna logs em ordem decrescente de inserção
Future<List<AdaptLogEntry>> getLogs({int? limit, AdaptLogLevel? level});

// Remove todos os logs
Future<void> clearLogs();
```

## Schema do banco

```sql
CREATE TABLE logs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  message     TEXT    NOT NULL,
  level       TEXT    NOT NULL,
  timestamp   TEXT    NOT NULL,
  stack_trace TEXT,
  metadata    TEXT              -- JSON
);
```

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
