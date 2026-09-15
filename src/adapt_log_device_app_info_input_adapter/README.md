# adapt_log_device_app_info_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_device_app_info_input_adapter.svg)](https://pub.dev/packages/adapt_log_device_app_info_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Input adapter que captura automaticamente informações do dispositivo e da aplicação e as anexa como metadados em cada `AdaptLogEntry`. Não emite logs por conta própria — apenas enriquece os logs emitidos pelos demais inputs.

## O que captura

**Dispositivo:**
- Fabricante e modelo
- Sistema operacional e versão
- SDK (Android) / versão do sistema (iOS/macOS/Windows/Linux)

**Aplicação:**
- Nome do app
- Versão e build number
- Package name

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_device_app_info_input_adapter: ^1.0.0
```

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_device_app_info_input_adapter/adapt_log_device_app_info_input_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [
    DeviceAppInfoInputAdapter(), // enriquece antes de despachar
    log,
  ],
  outputs: [/* seu output aqui */],
);
await adaptLog.initialize();

// Todo log emitido por TextLogInputAdapter terá os metadados do device/app
await log.info('App iniciado');
// entry.metadata conterá: app.version, app.name, device.model, device.os, etc.
```

## Metadados adicionados

| Chave | Exemplo |
|---|---|
| `app.name` | `Meu App` |
| `app.version` | `2.1.0` |
| `app.buildNumber` | `42` |
| `app.packageName` | `com.exemplo.meuapp` |
| `device.brand` | `Samsung` _(Android)_ |
| `device.model` | `Galaxy S24` |
| `device.os` | `Android 14` / `iOS 17.4` |
| `device.sdkInt` | `34` _(Android)_ |

## Como funciona

`DeviceAppInfoInputAdapter` sobrescreve o método `enrichEntry()` do `AdaptLogInput`. O `AdaptLogController` passa cada entry por todos os `enrichEntry()` registrados antes de despachá-la para os outputs — sem nenhum custo adicional para os demais adapters.

## Dependências

| Pacote | Papel |
|---|---|
| `adapt_log` | Contrato `AdaptLogInput` |
| `device_info_plus` | Coleta informações do dispositivo |
| `package_info_plus` | Coleta metadados da aplicação |

## Pacotes relacionados

- [`adapt_log`](../adapt_log/) — core do ecossistema
- [`adapt_log_sqlite_database_output_adapter`](../adapt_log_sqlite_database_output_adapter/) — persiste os logs enriquecidos em SQLite

## Licença

MIT
