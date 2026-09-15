# adapt_log_server

> **Módulo Closed Source / Pago** — disponível via assinatura. Não publicado no pub.dev.

Servidor Dart que recebe, armazena e serve os logs transmitidos pelos clientes via [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/). É a base do painel web de acompanhamento em tempo real.

## O que faz

- Aceita conexões WebSocket/HTTP de múltiplos clients (`RealTimeRemoteLogOutputAdapter`)
- Persiste os logs recebidos via [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/)
- Expõe API REST para o painel web consultar e filtrar logs por usuário, sessão e nível
- Roda como serviço independente — não faz parte do pacote instalado na aplicação cliente

## Inicialização

```dart
import 'package:adapt_log_server/adapt_log_server.dart';

final server = AdaptLogServer(
  port: 8080,
  dbPath: '/var/data/logs.sqlite',
);

await server.start();
```

## API

### `AdaptLogServer`

| Parâmetro | Tipo | Padrão | Descrição |
|---|---|---|---|
| `port` | `int` | `8080` | Porta HTTP/WebSocket |
| `dbPath` | `String` | — | Caminho do arquivo SQLite no servidor |

### Endpoints (painel web)

| Método | Path | Descrição |
|---|---|---|
| `GET` | `/logs` | Lista logs com filtros opcionais (`level`, `session`, `limit`) |
| `GET` | `/logs/:id` | Detalhe de um log |
| `WS` | `/stream` | Stream em tempo real de novos logs |

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log_sqlite_database_output_adapter` | Persistência dos logs recebidos |
| `shelf` | Framework HTTP/WebSocket para Dart |
| `shelf_router` | Roteamento REST |

## Pacotes relacionados

- [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/) — adapter do cliente que envia logs a este servidor
- [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/) — camada de persistência usada internamente

## Como adquirir

Entre em contato para informações sobre assinatura e acesso ao módulo.
