# adapt_log_real_time_remote_log_output_adapter

> **Módulo Closed Source / Pago** — disponível via assinatura. Não publicado no pub.dev.

Output adapter que transmite logs em tempo real para o [`adapt_log_server`](../adapt_log_server/), permitindo acompanhamento remoto das sessões dos usuários via painel web.

## O que faz

- Recebe cada `AdaptLogEntry` e a envia ao servidor via WebSocket/HTTP
- Usa o [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/) como buffer local: logs são gravados primeiro no SQLite e sincronizados com o servidor, garantindo entrega mesmo offline
- Não exibe logs localmente — apenas transmite

## Configuração

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_real_time_remote_log_output_adapter/adapt_log_real_time_remote_log_output_adapter.dart';
import 'package:adapt_log_sqlite_database_output_adapter/adapt_log_sqlite_database_output_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [log],
  outputs: [
    SqliteDatabaseOutputAdapter(),  // buffer local obrigatório
    RealTimeRemoteLogOutputAdapter(
      serverUrl: 'https://logs.meuapp.com',
      apiKey: 'SEU_API_KEY',
    ),
  ],
);
await adaptLog.initialize();
```

## API

### `RealTimeRemoteLogOutputAdapter`

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `serverUrl` | `String` | URL do servidor `adapt_log_server` |
| `apiKey` | `String` | Chave de autenticação fornecida na assinatura |

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogOutput` |
| `adapt_log_sqlite_database_output_adapter` | Buffer local para garantia de entrega |

## Pacotes relacionados

- [`adapt_log_server`](../adapt_log_server/) — servidor que recebe os logs transmitidos
- [`adapt_log_report_log_input_adapter`](../adapt_log_report_log_input_adapter/) — requer este adapter para envio de reports ao servidor
- [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/) — deve ser registrado junto como buffer

## Como adquirir

Entre em contato para informações sobre assinatura e acesso ao módulo.
