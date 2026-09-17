import 'package:adapt_log/adapt_log.dart';

/// Input adapter para logs da camada nativa do SO (Android Logcat, iOS
/// os_log/NSLog).
///
/// A ponte nativa (MethodChannel/EventChannel) ainda não foi implementada:
/// hoje este adapter não emite nenhuma entry. A API pública será mantida
/// quando a ponte for adicionada.
class NativeLogInputAdapter extends AdaptLogInput {}
