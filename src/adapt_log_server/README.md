# adapt_log_server

> **Módulo Closed Source / Pago** — disponível via assinatura. Não publicado no pub.dev.

Servidor Dart que recebe os lotes enviados pelo [`adapt_log_real_time_remote_log_output_adapter`](../adapt_log_real_time_remote_log_output_adapter/), persiste em SQLite e serve a API e o painel web de acompanhamento em tempo real.

## O que faz

- Recebe lotes em `POST /v1/logs`, autenticados por chave de API; cada chave pertence a um projeto e só enxerga o próprio projeto
- Deduplica pelo `id` da entry, então reenvios do cliente não geram duplicatas
- Persiste em SQLite via `package:sqlite3` (Dart puro, sem Flutter)
- Agrega sessões: início, último contato, metadata do app e contadores de entries e erros
- Extrai as screenshots enviadas pelo `adapt_log_flutter_error_screenshot_input_adapter` para uma tabela própria, marca a entry de erro com `hasScreenshot` e serve o PNG em `/v1/logs/<id>/screenshot`
- Difunde cada entry aceita pelo WebSocket `/v1/stream`
- Serve em `GET /` um painel web autossuficiente: lista ao vivo, filtros por nível, sessão e texto, e detalhe da entry com erro, **tela no momento do erro**, **prints capturados antes do erro**, stack trace, report e metadata

## Executar

```sh
cd src/adapt_log_server
ADAPT_LOG_API_KEYS="minha-chave:meu-app" dart run bin/adapt_log_server.dart
# adapt_log_server em http://localhost:8080 (projetos: meu-app)
```

| Variável | Padrão | Descrição |
|---|---|---|
| `ADAPT_LOG_API_KEYS` | — | Obrigatória. `chave:projeto[,chave2:projeto2]` |
| `PORT` | `8080` | Porta HTTP |
| `HOST` | `0.0.0.0` | Endereço de escuta |
| `ADAPT_LOG_DB` | `adapt_log.sqlite` | Caminho do banco SQLite |

Abra `http://localhost:8080` no navegador e informe a chave do projeto. A chave fica no `localStorage` do navegador.

### Docker

```sh
# na raiz do monorepo
docker build -f src/adapt_log_server/Dockerfile -t adapt_log_server .
docker run -p 8080:8080 -v adapt_log_data:/data -e ADAPT_LOG_API_KEYS="minha-chave:meu-app" adapt_log_server
```

### Em código

```dart
import 'package:adapt_log_server/adapt_log_server.dart';

final server = AdaptLogServer(
  port: 8080,
  dbPath: '/var/data/logs.sqlite',
  apiKeys: {'minha-chave': 'meu-app'},
);
await server.start();
print(server.url);
await server.stop();
```

`port: 0` escolhe uma porta livre (`server.boundPort`), e `dbPath: ':memory:'` usa um banco em memória; os dois são úteis em testes.

## API

Toda rota `/v1/*` exige `Authorization: Bearer <chave>`. O WebSocket aceita também `?key=<chave>`. Respostas são JSON; erros vêm como `{"error": "..."}` com 400, 401, 403, 404 ou 413.

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/` | Painel web |
| `GET` | `/health` | `{"status":"ok","protocolVersion":1}` |
| `POST` | `/v1/logs` | Recebe um `LogBatch`; responde `202 {"accepted": n, "stored": m}` |
| `GET` | `/v1/logs` | Lista entries, das mais recentes para as mais antigas. Query: `level`, `session`, `search`, `limit` (máx. 1000), `before` (cursor `seq`). Responde `{"entries": [...], "nextBefore": seq}` |
| `GET` | `/v1/logs/<id>` | Uma entry pelo `id` |
| `GET` | `/v1/logs/<id>/screenshot` | PNG da tela, pelo `id` do erro ou da entry de screenshot; aceita `?key=` para uso em `<img>` |
| `GET` | `/v1/sessions` | Sessões do projeto com contadores. Query: `limit` |
| `WS` | `/v1/stream` | Envia `{"type":"hello",...}` e depois um `LogStreamEvent` por entry aceita |

Cada entry na resposta traz os campos de `AdaptLogEntry.toJson()` mais `seq`, `sessionId` e `receivedAt`. O formato dos lotes e eventos está em [`adapt_log_remote_protocol`](../adapt_log_remote_protocol/).

## Arquitetura

Clean Architecture em quatro camadas dentro de `lib/src/`:

| Camada | Conteúdo |
|---|---|
| `domain/` | `LogRecord`, `SessionRecord`, `LogQuery` e o port `LogRepository` |
| `application/` | `IngestLogs` (grava e difunde) e `LogStream` (broadcast por projeto) |
| `infrastructure/` | `SqliteLogRepository` (tabelas `logs`, `sessions` e `screenshots`) |
| `presentation/` | `ApiRouter` (shelf + shelf_router + shelf_web_socket) e o painel |

`AdaptLogServer` é a raiz de composição. Um `LogRepository` alternativo pode ser injetado.

## Limites desta versão

- Uma instância por banco; sem TLS. Coloque atrás de um proxy reverso com HTTPS.
- Sem retenção automática no servidor.
- O painel usa a mesma chave da API; não há usuários nem permissões.
- Exige `libsqlite3` no host (presente no macOS; no Debian, `libsqlite3-0`, já incluído no Dockerfile).

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | `AdaptLogEntry` e serialização |
| `adapt_log_remote_protocol` | `LogBatch`, `SessionInfo`, `LogStreamEvent` |
| `shelf`, `shelf_router`, `shelf_web_socket` | HTTP e WebSocket |
| `sqlite3` | Persistência |

## Licença

Proprietária, todos os direitos reservados. Veja o [LICENSE](LICENSE). Este pacote não está coberto pela licença MIT dos pacotes open source do repositório.

## Como adquirir

Entre em contato para informações sobre assinatura e acesso ao módulo.
