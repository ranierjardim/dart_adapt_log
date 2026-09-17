# adapt_log_device_app_info_input_adapter

[![pub.dev](https://img.shields.io/pub/v/adapt_log_device_app_info_input_adapter.svg)](https://pub.dev/packages/adapt_log_device_app_info_input_adapter)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-blue)](https://flutter.dev)

Input adapter que coleta, uma única vez em `initialize()`, informações do dispositivo e da aplicação e as anexa como metadados em cada `AdaptLogEntry`. Não emite logs por conta própria; apenas enriquece os logs emitidos pelos demais inputs.

## O que captura

**Aplicação:** nome, versão, build number e package name.

**Dispositivo:** fabricante/modelo, sistema operacional e versão, SDK (Android). Na web, navegador e user agent.

## Instalação

```yaml
dependencies:
  adapt_log: ^1.0.0
  adapt_log_device_app_info_input_adapter: ^1.0.0
```

Requer Dart 3.3+ e Flutter 3.19+ (`device_info_plus` e `package_info_plus`).

## Uso

```dart
import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_device_app_info_input_adapter/adapt_log_device_app_info_input_adapter.dart';
import 'package:adapt_log_text_log_input_adapter/adapt_log_text_log_input_adapter.dart';

final log = TextLogInputAdapter();

final adaptLog = AdaptLog(
  inputs: [
    DeviceAppInfoInputAdapter(),
    log,
  ],
  outputs: [/* seu output aqui */],
);
await adaptLog.initialize();

// Todo log emitido terá os metadados do device/app
await log.info('App iniciado');
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
| `device.name` | `iPhone de Ana` _(iOS)_ |
| `device.os` | `Android 14` / `iOS 17.4` / `macOS 23.4.0` |
| `device.sdkInt` | `34` _(Android)_ |
| `device.browser` | `chrome` _(web)_ |
| `device.userAgent` | `Mozilla/5.0 ...` _(web)_ |

Chaves já presentes em `entry.metadata` prevalecem sobre as coletadas.

## Como funciona

`DeviceAppInfoInputAdapter` sobrescreve `enrichEntry()`. Falhas de coleta, como plugin indisponível ou plataforma sem suporte, são reportadas em `AdaptLog.onError` e o adapter segue com o que conseguiu coletar; as informações ficam disponíveis em `adapter.info`.

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
