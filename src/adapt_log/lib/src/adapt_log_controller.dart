

import 'dart:isolate';
import 'package:adapt_log/adapt_log.dart';

class AdaptLogController {

  final AdaptLog instance;
  const AdaptLogController(this.instance);

  Future<void> log(AdaptLogObjectMixin object) async {
    
    final p = ReceivePort();
    // final f = ExemploIso(p.sendPort);
    

    // await Isolate.current.debugName;
    
    if(instance.adaptLogDataPort != null) {
      instance.adaptLogDataPort!.onNewLog(object);
    } else {
      for (final adapter in instance.adaptLogOutputPorts) {
        adapter.onNewLog(object);
      }
    }
  }

  Future<List<dynamic>> getLogObjects() async {
    if(instance.adaptLogDataPort != null) {
      return await instance.adaptLogDataPort!.getLogObjects();
    }
    throw Exception('No data port specified');
  }

}