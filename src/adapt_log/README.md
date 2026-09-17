# adapt_log

[![pub.dev](https://img.shields.io/pub/v/adapt_log.svg)](https://pub.dev/packages/adapt_log)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Core do ecossistema `dart_adapt_log`. Define os contratos de entrada e saída de log e orquestra o fluxo entre todos os adapters registrados.

## O que faz

- Expõe as abstrações `AdaptLogInput` e `AdaptLogOutput` para implementação pelos adapters
- Recebe logs via `AdaptLogController.log()` e os distribui a todos os outputs registrados
- Executa o pipeline de enriquecimento (`enrichEntry()`) antes de despachar aos outputs
- Isola falhas de adapters e as entrega a `AdaptLog.onError`
- Não implementa nenhuma entrada ou saída concreta; isso é responsabilidade dos adapters

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
```

## Conceitos

### AdaptLogEntry

Registro de log imutável. Use `copyWith()` para derivar outra entry.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `String` | Identificador único gerado no cliente (`AdaptLogEntry.generateId()`) |
| `message` | `String` | Mensagem do log |
| `level` | `AdaptLogLevel` | `debug`, `info`, `warning`, `error` (o `index` cresce com a severidade) |
| `timestamp` | `DateTime` | Momento do log (padrão: `DateTime.now()`) |
| `error` | `Object?` | Exceção ou `Error` original; `errorType` dá o tipo como texto |
| `stackTrace` | `StackTrace?` | Stack trace opcional |
| `metadata` | `Map<String, dynamic>` | Metadados adicionais, sempre imutáveis |

`toJson()` produz um mapa estável (timestamp em UTC, `error` e `errorType` como texto, metadata passada por `AdaptLogEntry.jsonSafe`) e `AdaptLogEntry.fromJson()` o reconstrói; o `error` volta como `AdaptLogSerializedError`. É o formato usado pelos adapters de armazenamento e transporte.

### AdaptLogAdapter

Base comum de inputs e outputs. Guarda o `AdaptLogController` recebido em `initialize()` e o expõe às subclasses pelo getter protegido `controller`, que lança `StateError` se o adapter ainda não foi inicializado. Subclasses que sobrescrevem `initialize()` ou `shutdown()` devem chamar `super`.

### AdaptLogInput

Fonte de logs. Emite entries com `controller.log(entry)` e pode enriquecer todas as entries do pipeline sobrescrevendo `enrichEntry()`.

```dart
abstract class AdaptLogInput extends AdaptLogAdapter {
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) => entry;
}
```

`enrichEntry()` é chamado para cada entry, na ordem em que os inputs foram registrados. Deve ser síncrono; uma exceção é reportada em `onError` e a entry segue sem aquele enriquecimento. Chamar `controller.log()` de dentro dele é permitido: a nova entry entra na fila e é despachada depois da atual.

### AdaptLogOutput

Destino de logs.

```dart
abstract class AdaptLogOutput extends AdaptLogAdapter {
  Future<void> onNewLog(AdaptLogEntry entry);
}
```

Para cada output, `onNewLog()` recebe uma entry por vez, na ordem em que foram logadas. Outputs diferentes não bloqueiam uns aos outros. Um output não deve logar pelo pipeline: qualquer `log()` feito durante `onNewLog()`, direta ou indiretamente (por exemplo por um `print()` interceptado por um input), é descartado para evitar recursão infinita.

### AdaptLog

Orquestrador. Registra inputs e outputs e gerencia o ciclo de vida.

```dart
AdaptLog({
  required List<AdaptLogInput> inputs,
  required List<AdaptLogOutput> outputs,
  AdaptLogErrorHandler? onError, // (error, stackTrace, adapter)
})
```

| Método | Descrição |
|---|---|
| `initialize()` | Inicializa outputs e depois inputs. Idempotente. Falha em um adapter é reportada e os demais seguem |
| `shutdown()` | Aguarda as entries pendentes e encerra inputs e outputs na ordem inversa. Idempotente |
| `flush()` | Completa quando todas as entries já logadas foram processadas |
| `state` | `created`, `initializing`, `ready`, `shuttingDown`, `shutDown` |

`onError` padrão escreve no console pela zona raiz, sem passar por interceptadores de `print`.

### AdaptLogController

Ponto de entrada das entries. Recebido por cada adapter em `initialize()`.

```dart
await controller.log(AdaptLogEntry(message: 'mensagem', level: AdaptLogLevel.info));
```

`log()` retorna um `Future` que completa quando todos os outputs processaram a entry. Aguardá-lo é opcional. Garantias:

- nunca lança por falha de adapter;
- antes de `AdaptLog.initialize()` lança `StateError`; durante ou depois de `shutdown()` a entry é descartada;
- `controller.reportError(error, stackTrace, adapter)` encaminha a `onError` falhas de trabalho assíncrono feito fora do pipeline.

## Uso

### Implementando um input customizado

```dart
class MeuInputAdapter extends AdaptLogInput {
  Future<void> meuLog(String mensagem) {
    return controller.log(AdaptLogEntry(
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
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    // abrir conexões, arquivos...
  }

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async {
    print('[${entry.level.name}] ${entry.message}');
  }

  @override
  Future<void> shutdown() async {
    // fechar o que foi aberto
    await super.shutdown();
  }
}
```

### Conectando tudo

```dart
final input = MeuInputAdapter();

final adaptLog = AdaptLog(
  inputs: [input],
  outputs: [MeuOutputAdapter()],
  onError: (error, stackTrace, adapter) => print('$adapter falhou: $error'),
);

await adaptLog.initialize();
await input.meuLog('Olá, mundo!');
await adaptLog.shutdown();
```

## Adapters prontos

Use os adapters do ecossistema em vez de implementar do zero:

| Pacote | Descrição |
|---|---|
| `adapt_log_text_log_input_adapter` | Entrada textual com `debug/info/warning/error` |
| `adapt_log_logger_print_package_output_adapter` | Saída formatada no console |
| `adapt_log_sqlite_database_output_adapter` | Persistência em SQLite |
| [ver todos](https://github.com/ranierjardim/dart_adapt_log) | — |

## Licença

MIT
