import 'package:adapt_log/adapt_log.dart';
import 'package:adapt_log_device_app_info_input_adapter/adapt_log_device_app_info_input_adapter.dart';
import 'package:flutter/material.dart';

final _deviceInfo = DeviceAppInfoInputAdapter();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final adaptLog = AdaptLog(inputs: [_deviceInfo], outputs: const []);
  await adaptLog.initialize();

  runApp(const _ExampleApp());
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    final info = _deviceInfo.info;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('adapt_log: device/app info')),
        body: ListView(
          children: [
            for (final key in info.keys)
              ListTile(title: Text(key), subtitle: Text('${info[key]}')),
          ],
        ),
      ),
    );
  }
}
