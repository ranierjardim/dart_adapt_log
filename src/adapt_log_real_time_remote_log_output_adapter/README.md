# adapt_log_real_time_remote_log_output_adapter

> **Módulo Closed Source / Pago** — disponível via assinatura. Não publicado no pub.dev.

Output adapter que transmite as entries ao [`adapt_log_server`](../adapt_log_server/) em lotes, com buffer em memória e reenvio automático, para acompanhamento em tempo real no painel web.

## Como funciona

- Acumula entries e envia em lotes de até `batchSize` entries ou `maxBatchBytes` de JSON a cada `flushInterval`, ou imediatamente quando o lote enche; screenshots pesadas vão em lotes menores
- Cada envio é um `POST /v1/logs` com `Authorization: Bearer <apiKey>` e um `LogBatch` JSON (ver [`adapt_log_remote_protocol`](../adapt_log_remote_protocol/))
- Falhas de rede e respostas 5xx, 408 ou 429 mantêm o lote na fila e reenviam com backoff exponencial entre `initialBackoff` e `maxBackoff`; respostas 4xx descartam o lote
- A fila guarda no máximo `maxBufferedEntries`; acima disso as mais antigas são descartadas e contadas em `droppedEntries`
- A primeira falha de cada sequência e cada lote descartado vão para `AdaptLog.onError`
- `AdaptLog.shutdown()` tenta enviar o que restou antes de encerrar
- Uma sessão nova é criada em cada `initialize()`; `sessionMetadata` vai em todo lote e aparece no painel

## Configuração

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_real_time_remote_log_output_adapter/adapt_log_real_time_remote_log_output_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [log],
  outputs: [
    RealTimeRemoteLogOutputAdapter(
      serverUrl: 'https://logs.meuapp.com',
      apiKey: 'SEU_API_KEY',
      minLevel: AdaptLogLevel.info,
      sessionMetadata: {'app.name': 'Meu App', 'app.version': '2.1.0'},
    ),
  ],
);
await adaptLog.initialize();

await log.error('Falha no checkout', error: e, stackTrace: st);
```

Com [`adapt_log_flutter_auto_report_log_input_adapter`](../adapt_log_flutter_auto_report_log_input_adapter/) registrado, a entry de erro chega ao servidor com as últimas linhas de `debugPrint` em `metadata.recentPrints`, e o painel as mostra em "Prints antes do erro". Com [`adapt_log_flutter_error_screenshot_input_adapter`](../adapt_log_flutter_error_screenshot_input_adapter/), a tela no momento do erro chega junto.

## API

### `RealTimeRemoteLogOutputAdapter`

| Parâmetro | Padrão | Descrição |
|---|---|---|
| `serverUrl` | — | URL base do `adapt_log_server` |
| `apiKey` | — | Chave do projeto, fornecida na assinatura |
| `minLevel` | `debug` | Nível mínimo transmitido |
| `batchSize` | `50` | Entries por lote |
| `maxBatchBytes` | `4 MB` | Tamanho máximo do JSON de um lote; uma entry maior vai sozinha |
| `flushInterval` | `2s` | Espera máxima antes de enviar um lote incompleto |
| `maxBufferedEntries` | `5000` | Tamanho da fila em memória |
| `initialBackoff` / `maxBackoff` | `1s` / `30s` | Espera entre tentativas após falha |
| `requestTimeout` | `10s` | Timeout por requisição |
| `sessionMetadata` | `{}` | Informações fixas da sessão |
| `client` | — | `http.Client` injetável (testes) |

Leituras: `session`, `state` (`RemoteLogIdle`, `RemoteLogSending`, `RemoteLogBackingOff`, `RemoteLogStopped`), `pendingEntries`, `sentEntries`, `droppedEntries`. `flush()` força o envio do que está na fila.

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogOutput` |
| `adapt_log_remote_protocol` | Formato dos lotes |
| `http` | Transporte HTTP, inclusive na web |

## Licença

Proprietária, todos os direitos reservados. Veja o [LICENSE](LICENSE). Este pacote não está coberto pela licença MIT dos pacotes open source do repositório.

## Como adquirir

Entre em contato para informações sobre assinatura e acesso ao módulo.
