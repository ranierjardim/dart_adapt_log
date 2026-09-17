# adapt_log_remote_protocol

[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Contrato de transporte entre o cliente (`adapt_log_real_time_remote_log_output_adapter`) e o `adapt_log_server`: formato JSON dos lotes, das sessões e dos eventos de stream, mais as rotas e cabeçalhos. Os dois lados dependem deste pacote, e de mais nenhum um do outro.

## Formato

`POST /v1/logs` com `Authorization: Bearer <chave>` e `Content-Type: application/json`:

```json
{
  "protocolVersion": 1,
  "session": {
    "id": "hmbn6884ze-0000-1y2t0d5",
    "startedAt": "2026-09-15T16:39:58.517Z",
    "metadata": {"app.name": "Meu App", "app.version": "2.1.0"}
  },
  "entries": [
    {
      "id": "hmbn68a3kq-0002-0i8wanj",
      "message": "Falha no checkout",
      "level": "error",
      "timestamp": "2026-09-15T16:40:01.004Z",
      "error": "Bad state: gateway recusou o pagamento",
      "errorType": "StateError",
      "stackTrace": "#0 main (...)",
      "metadata": {"orderId": 1234, "recentPrints": ["abrindo tela de pagamento", "tocou em pagar"]}
    }
  ]
}
```

Evento do WebSocket `/v1/stream`, um por entry aceita:

```json
{"type": "entry", "project": "meu-app", "sessionId": "hmbn6884ze-0000-1y2t0d5", "entry": {"...": "..."}}
```

## API

| Tipo | Descrição |
|---|---|
| `AdaptLogProtocol` | `version`, rotas (`logsPath`, `sessionsPath`, `streamPath`, `healthPath`) e cabeçalhos |
| `SessionInfo` | `id`, `startedAt` (UTC), `metadata` |
| `LogBatch` | `session` + `entries`; `fromJson` lança `FormatException` para versão diferente ou corpo malformado |
| `LogStreamEvent` | `project`, `sessionId`, `entry` |

A entry usa `AdaptLogEntry.toJson()` / `fromJson()` do core.

## Convenções de metadata

Chaves que os adapters emitem e o servidor e o painel entendem:

| Chave | Origem | Significado |
|---|---|---|
| `recentPrints` | flutter_auto_report | Últimas linhas de `debugPrint` antes do erro |
| `isReport`, `reportContext`, `reportFor` | report / auto_report | Entry de report e o `id` do erro que a disparou |
| `isScreenshot`, `screenshotFor`, `screenshot`, `screenshotFormat`, `screenshotWidth`, `screenshotHeight` | flutter_error_screenshot | Entry de screenshot: PNG em base64 e o `id` do erro |
| `hasScreenshot` | servidor | Marcada na entry de erro e na de screenshot depois que a imagem foi extraída |
| `app.*`, `device.*` | device_app_info | Informações do app e do dispositivo |
| `source` | uncatched_flutter_exception | `FlutterError`, `PlatformDispatcher` ou `zone` |

## Licença

MIT
