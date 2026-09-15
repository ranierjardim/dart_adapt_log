# adapt_log

[![pub.dev](https://img.shields.io/pub/v/adapt_log.svg)](https://pub.dev/packages/adapt_log)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Core do ecossistema `dart_adapt_log`. Define os contratos de entrada e saída de log e orquestra o fluxo entre todos os adapters registrados.

## O que faz

- Expõe as abstrações `AdaptLogInput` e `AdaptLogOutput` para implementação pelos adapters
- Recebe logs via `AdaptLogController.log()` e os distribui a todos os outputs registrados
- Executa pipeline de enriquecimento de metadados antes de despachar para os outputs
- Não implementa nenhuma entrada ou saída concreta — isso é responsabilidade dos adapters

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
```

## Conceitos

### AdaptLogEntry

Representa um registro de log.

| Campo | Tipo | Descrição |
|---|---|---|
| `message` | `String` | Mensagem do log |
| `level` | `AdaptLogLevel` | Nível: `debug`, `info`, `warning`, `error` |
| `timestamp` | `DateTime` | Momento do log (padrão: `DateTime.now()`) |
| `stackTrace` | `StackTrace?` | Stack trace opcional |
| `metadata` | `Map<String, dynamic>` | Metadados adicionais (enriquecidos por inputs) |

### AdaptLogInput

Contrato para adapters de entrada. Implemente para criar uma nova fonte de logs.

```dart
abstract class AdaptLogInput {
  Future<void> initialize(AdaptLogController controller);
  Future<void> shutdown();

  // Sobrescreva para enriquecer entries com metadados adicionais
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) => entry;
}
```

### AdaptLogOutput

Contrato para adapters de saída. Implemente para criar um novo destino de logs.

```dart
abstract class AdaptLogOutput {
  Future<void> initialize(AdaptLogController controller);
  Future<void> shutdown();
  Future<void> onNewLog(AdaptLogEntry entry);
}
```

### AdaptLog

Orquestrador central. Registra inputs e outputs e gerencia o ciclo de vida.

```dart
AdaptLog({
  required List<AdaptLogInput> inputs,
  required List<AdaptLogOutput> outputs,
})
```

### AdaptLogController

Ponto de entrada para emissão de logs. Recebido por cada adapter via `initialize()`.

```dart
await controller.log(AdaptLogEntry(
  message: 'mensagem',
  level: AdaptLogLevel.info,
));
```

## Uso

### Implementando um input customizado

```dart
class MeuInputAdapter extends AdaptLogInput {
  late AdaptLogController _controller;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _controller = controller;
  }

  @override
  Future<void> shutdown() async {}

  Future<void> meuLog(String mensagem) async {
    await _controller.log(AdaptLogEntry(
      message: mensagem,
      level: AdaptLogLevel.info,
    ));
  }
}
```

### Implementando um output customizado

```dart
class MeuOutputAdapter extends AdaptLogOutput {
  @override
  Future<void> initialize(AdaptLogController controller) async {}

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    // Faça algo com entry: salvar, enviar, imprimir...
    print('[${entry.level.name}] ${entry.message}');
  }

  @override
  Future<void> shutdown() async {}
}
```

### Conectando tudo

```dart
final input = MeuInputAdapter();

final adaptLog = AdaptLog(
  inputs: [input],
  outputs: [MeuOutputAdapter()],
);

await adaptLog.initialize();
await input.meuLog('Olá, mundo!');
await adaptLog.shutdown();
```

## Adapters prontos

Use os adapters do ecossistema em vez de implementar do zero:

| Pacote | Descrição |
|---|---|
| `adapt_log_text_log_input_adapter` | Entrada textual com `info/warning/error/debug` |
| `adapt_log_logger_print_package_output_adapter` | Saída formatada no console |
| `adapt_log_sqlite_database_output_adapter` | Persistência em SQLite |
| [ver todos](https://github.com/ranierjardim/dart_adapt_log) | — |

## Licença

MIT
