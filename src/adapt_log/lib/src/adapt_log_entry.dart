import 'adapt_log_level.dart';

class AdaptLogEntry {
  final String message;
  final AdaptLogLevel level;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final Map<String, dynamic> metadata;

  AdaptLogEntry({
    required this.message,
    required this.level,
    DateTime? timestamp,
    this.stackTrace,
    Map<String, dynamic>? metadata,
  })  : timestamp = timestamp ?? DateTime.now(),
        metadata = metadata ?? const {};

  AdaptLogEntry copyWith({Map<String, dynamic>? metadata}) {
    return AdaptLogEntry(
      message: message,
      level: level,
      timestamp: timestamp,
      stackTrace: stackTrace,
      metadata: metadata ?? this.metadata,
    );
  }
}
