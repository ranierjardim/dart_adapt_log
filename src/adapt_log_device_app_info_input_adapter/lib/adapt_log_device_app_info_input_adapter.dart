library adapt_log_device_app_info_input_adapter;

import 'dart:io';

import 'package:adapt_log/adapt_log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceAppInfoInputAdapter extends AdaptLogInput {
  Map<String, dynamic> _info = {};

  @override
  Future<void> initialize(AdaptLogController controller) async {
    _info = await _collect();
  }

  @override
  Future<void> shutdown() async {}

  @override
  AdaptLogEntry enrichEntry(AdaptLogEntry entry) {
    return entry.copyWith(metadata: {...entry.metadata, ..._info});
  }

  Future<Map<String, dynamic>> _collect() async {
    final result = <String, dynamic>{};

    final packageInfo = await PackageInfo.fromPlatform();
    result['app.name'] = packageInfo.appName;
    result['app.version'] = packageInfo.version;
    result['app.buildNumber'] = packageInfo.buildNumber;
    result['app.packageName'] = packageInfo.packageName;

    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      result['device.brand'] = info.brand;
      result['device.model'] = info.model;
      result['device.os'] = 'Android ${info.version.release}';
      result['device.sdkInt'] = info.version.sdkInt;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      result['device.name'] = info.name;
      result['device.model'] = info.model;
      result['device.os'] = '${info.systemName} ${info.systemVersion}';
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      result['device.model'] = info.model;
      result['device.os'] = 'macOS ${info.osRelease}';
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      result['device.os'] = 'Windows ${info.displayVersion}';
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      result['device.os'] = '${info.name} ${info.version}';
    }

    return result;
  }
}
