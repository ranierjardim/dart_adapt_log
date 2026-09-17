library adapt_log_device_app_info_input_adapter;

import 'package:adapt_log/adapt_log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Enriquece toda entry com informações do app e do dispositivo, coletadas
/// uma única vez em [initialize]. Não emite entries.
///
/// Chaves já presentes em `entry.metadata` prevalecem sobre as coletadas.
/// Falhas de coleta (plugin indisponível, plataforma sem suporte) são
/// reportadas em `AdaptLog.onError` e o adapter segue com o que conseguiu.
class DeviceAppInfoInputAdapter extends AdaptLogInput {
  Map<String, dynamic> _info = const {};

  /// Informações coletadas em [initialize].
  Map<String, dynamic> get info => _info;

  @override
  Future<void> initialize(AdaptLogController controller) async {
    await super.initialize(controller);
    _info = Map<String, dynamic>.unmodifiable(await _collect());
  }

  @override
  Future<void> shutdown() async {
    _info = const {};
    await super.shutdown();
  }

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    if (_info.isEmpty) return entry;
    return entry.copyWith(metadata: {..._info, ...entry.metadata});
  }

  Future<Map<String, dynamic>> _collect() async {
    final result = <String, dynamic>{};

    await _attempt(() async {
      final packageInfo = await PackageInfo.fromPlatform();
      result['app.name'] = packageInfo.appName;
      result['app.version'] = packageInfo.version;
      result['app.buildNumber'] = packageInfo.buildNumber;
      result['app.packageName'] = packageInfo.packageName;
    });

    await _attempt(() async {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final info = await deviceInfo.webBrowserInfo;
        result['device.browser'] = info.browserName.name;
        result['device.os'] = info.platform ?? 'web';
        result['device.userAgent'] = info.userAgent;
        return;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await deviceInfo.androidInfo;
          result['device.brand'] = info.brand;
          result['device.model'] = info.model;
          result['device.os'] = 'Android ${info.version.release}';
          result['device.sdkInt'] = info.version.sdkInt;
        case TargetPlatform.iOS:
          final info = await deviceInfo.iosInfo;
          result['device.name'] = info.name;
          result['device.model'] = info.model;
          result['device.os'] = '${info.systemName} ${info.systemVersion}';
        case TargetPlatform.macOS:
          final info = await deviceInfo.macOsInfo;
          result['device.model'] = info.model;
          result['device.os'] = 'macOS ${info.osRelease}';
        case TargetPlatform.windows:
          final info = await deviceInfo.windowsInfo;
          result['device.os'] = 'Windows ${info.displayVersion}';
        case TargetPlatform.linux:
          final info = await deviceInfo.linuxInfo;
          result['device.os'] = '${info.name} ${info.version}';
        case TargetPlatform.fuchsia:
          result['device.os'] = 'Fuchsia';
      }
    });

    return result;
  }

  Future<void> _attempt(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      controller.reportError(error, stackTrace, this);
    }
  }
}
