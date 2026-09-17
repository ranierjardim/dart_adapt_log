import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_device_app_info_input_adapter/adapt_log_device_app_info_input_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Emitter extends AdaptLogInput {
  Future<void> emit(String message, {Map<String, dynamic>? metadata}) {
    return controller.log(AdaptLogEntry(message: message, level: AdaptLogLevel.info, metadata: metadata));
  }
}

class Collector extends AdaptLogOutput {
  final entries = <AdaptLogEntry>[];

  @override
  Future<void> onNewLog(AdaptLogEntry entry) async => entries.add(entry);
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Meu App',
      packageName: 'com.exemplo.meuapp',
      version: '2.1.0',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('anexa app.* e device.* a toda entry; chaves do usuário prevalecem', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final emitter = Emitter();
    final out = Collector();
    final errors = <Object>[];
    final adaptLog = AdaptLog(
      inputs: [DeviceAppInfoInputAdapter(), emitter],
      outputs: [out],
      onError: (error, _, __) => errors.add(error),
    );
    await adaptLog.initialize();

    await emitter.emit('oi', metadata: {'app.name': 'override', 'userId': 7});

    final metadata = out.entries.single.metadata;
    expect(errors, isEmpty);
    expect(metadata['app.name'], 'override');
    expect(metadata['app.version'], '2.1.0');
    expect(metadata['app.buildNumber'], '42');
    expect(metadata['app.packageName'], 'com.exemplo.meuapp');
    expect(metadata['device.os'], 'Fuchsia');
    expect(metadata['userId'], 7);
    await adaptLog.shutdown();
  });

  test('plugin de device indisponível: erro reportado e app.* ainda presentes', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final adapter = DeviceAppInfoInputAdapter();
    final errors = <Object>[];
    final adaptLog = AdaptLog(
      inputs: [adapter],
      outputs: const [],
      onError: (error, _, __) => errors.add(error),
    );

    await adaptLog.initialize();

    expect(adaptLog.isReady, isTrue);
    expect(errors, hasLength(1));
    expect(adapter.info['app.name'], 'Meu App');
    expect(adapter.info.keys.where((k) => k.startsWith('device.')), isEmpty);
    await adaptLog.shutdown();
  });
}
