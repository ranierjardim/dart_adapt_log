import 'package:adapt_log/adapt_log.dart';

enum AdaptLogDefaultTextInputLevel {
  off,
  shout,
  severe,
  warning,
  info,
  config,
  fine,
  finer,
  finest,
  all,
}

extension AdaptLogDefaultTextInputLevelExtension on AdaptLogDefaultTextInputLevel {
  String asString() {
    switch (this) {
      case AdaptLogDefaultTextInputLevel.shout:
        return 'shout';
      case AdaptLogDefaultTextInputLevel.severe:
        return 'severe';
      case AdaptLogDefaultTextInputLevel.warning:
        return 'warning';
      case AdaptLogDefaultTextInputLevel.info:
        return 'info';
      case AdaptLogDefaultTextInputLevel.config:
        return 'config';
      case AdaptLogDefaultTextInputLevel.fine:
        return 'fine';
      case AdaptLogDefaultTextInputLevel.finer:
        return 'finer';
      case AdaptLogDefaultTextInputLevel.finest:
        return 'finest';
      default:
        return 'Unknown';
    }
  }

  int get value {
    switch (this) {
      case AdaptLogDefaultTextInputLevel.off:
        return 2000;
      case AdaptLogDefaultTextInputLevel.shout:
        return 1200;
      case AdaptLogDefaultTextInputLevel.severe:
        return 1000;
      case AdaptLogDefaultTextInputLevel.warning:
        return 900;
      case AdaptLogDefaultTextInputLevel.info:
        return 800;
      case AdaptLogDefaultTextInputLevel.config:
        return 700;
      case AdaptLogDefaultTextInputLevel.fine:
        return 500;
      case AdaptLogDefaultTextInputLevel.finer:
        return 400;
      case AdaptLogDefaultTextInputLevel.finest:
        return 300;
      case AdaptLogDefaultTextInputLevel.all:
        return 0;
      default:
        return 1200;
    }
  }

  bool operator <(Object other) => other is AdaptLogDefaultTextInputLevel ? value < other.value : false;

  bool operator <=(Object other) => other is AdaptLogDefaultTextInputLevel ? value <= other.value : false;

  bool operator >(Object other) => other is AdaptLogDefaultTextInputLevel ? value > other.value : false;

  bool operator >=(Object other) => other is AdaptLogDefaultTextInputLevel ? value >= other.value : false;
}

mixin AdaptLogDefaultTextInputObjectMixin implements AdaptLogObjectMixin {
  AdaptLogDefaultTextInputLevel get defaultTextInputLevel;

  @override
  final DateTime currentTime = DateTime.now();

  bool get shouldPrint;
}

class AdaptLogDefaultTextInputObject with AdaptLogDefaultTextInputObjectMixin {
  final AdaptLogDefaultTextInputLevel _adaptLogDefaultTextInputLevel;
  final String _text;
  final bool _shouldPrint;

  AdaptLogDefaultTextInputObject(this._adaptLogDefaultTextInputLevel, this._text, this._shouldPrint);

  @override
  AdaptLogDefaultTextInputLevel get defaultTextInputLevel => _adaptLogDefaultTextInputLevel;

  @override
  String get toLogString => _text;

  @override
  bool get shouldPrint => _shouldPrint;
}

class AdaptLogDefaultTextInputAdapter extends AdaptLogInputPort {

  final AdaptLogDefaultTextInputLevel propagateLevel;
  final AdaptLogDefaultTextInputLevel printLevel;
  late final AdaptLogController adaptLogController;

  AdaptLogDefaultTextInputAdapter({
    this.propagateLevel = AdaptLogDefaultTextInputLevel.info,
    this.printLevel = AdaptLogDefaultTextInputLevel.info,
  });

  @override
  Future<void> initialize(AdaptLogController adaptLogController) async {
    this.adaptLogController = adaptLogController;
  }

  @override
  Future<void> shutdown() async {}

  Future<void> sendToController(AdaptLogDefaultTextInputLevel level, String text) async {
    if(level >= propagateLevel) {
      adaptLogController.log(AdaptLogDefaultTextInputObject(AdaptLogDefaultTextInputLevel.shout, text, level >= printLevel));
    }
  }

  Future<void> shout(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.shout, text);
  }

  Future<void> severe(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.severe, text);
  }

  Future<void> warning(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.warning, text);
  }

  Future<void> info(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.info, text);
  }

  Future<void> config(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.config, text);
  }

  Future<void> fine(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.fine, text);
  }

  Future<void> finer(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.finer, text);
  }

  Future<void> finest(String text) async {
    sendToController(AdaptLogDefaultTextInputLevel.finest, text);
  }
}
