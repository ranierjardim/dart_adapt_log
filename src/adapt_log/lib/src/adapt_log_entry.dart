import 'dart:math';

import 'adapt_log_level.dart';

/// Um registro de log. Imutável: use [copyWith] para derivar outra entry.
class AdaptLogEntry {
  /// Identificador único da entry, gerado no cliente. Serve para deduplicar
  /// no servidor e para relacionar entries (por exemplo report → erro).
  final String id;
  final String message;
  final AdaptLogLevel level;
  final DateTime timestamp;

  /// Objeto de erro original, quando houver (exceção, `Error`...). Ao
  /// serializar vira `error` (texto) e `errorType` (tipo).
  final Object? error;
  final StackTrace? stackTrace;

  /// Metadados adicionais. Sempre imutável; inputs enriquecem via [copyWith].
  final Map<String, dynamic> metadata;

  AdaptLogEntry({
    String? id,
    required this.message,
    required this.level,
    DateTime? timestamp,
    this.error,
    this.stackTrace,
    Map<String, dynamic>? metadata,
  })  : id = id ?? generateId(),
        timestamp = timestamp ?? DateTime.now(),
        metadata = metadata == null || metadata.isEmpty
            ? const {}
            : Map<String, dynamic>.unmodifiable(metadata);

  /// Reconstrói uma entry a partir de [toJson]. O `error` volta como
  /// [AdaptLogSerializedError], preservando tipo e texto.
  factory AdaptLogEntry.fromJson(Map<String, dynamic> json) {
    final errorText = json['error'] as String?;
    final stackTrace = json['stackTrace'] as String?;
    final metadata = json['metadata'];
    return AdaptLogEntry(
      id: json['id'] as String?,
      message: json['message'] as String,
      level: AdaptLogLevel.values.byName(json['level'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: errorText == null
          ? null
          : AdaptLogSerializedError(
              type: json['errorType'] as String? ?? 'Object',
              message: errorText,
            ),
      stackTrace: stackTrace == null ? null : StackTrace.fromString(stackTrace),
      metadata: metadata is Map ? Map<String, dynamic>.from(metadata) : null,
    );
  }

  static int _counter = 0;
  static final Random _random = Random();

  /// Gera um id único: instante em micros, contador e parte aleatória,
  /// tudo em base 36.
  static String generateId() {
    final time = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);
    final counter = (_counter++ & 0xFFFF).toRadixString(36).padLeft(4, '0');
    final random = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$time-$counter-$random';
  }

  /// Tipo do [error], como texto, ou `null`.
  String? get errorType {
    final error = this.error;
    if (error == null) return null;
    if (error is AdaptLogSerializedError) return error.type;
    return error.runtimeType.toString();
  }

  /// Representação JSON estável, usada pelos adapters de transporte e
  /// armazenamento. `timestamp` sai em UTC.
  Map<String, dynamic> toJson() {
    final error = this.error;
    final stackTrace = this.stackTrace;
    return {
      'id': id,
      'message': message,
      'level': level.name,
      'timestamp': timestamp.toUtc().toIso8601String(),
      if (error != null) 'error': error.toString(),
      if (error != null) 'errorType': errorType,
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      'metadata': jsonSafe(metadata) as Map<String, dynamic>,
    };
  }

  /// Converte [value] em algo que `jsonEncode` aceita: mapas viram mapas
  /// com chave texto, iteráveis viram listas e qualquer outro objeto vira
  /// `toString()`.
  static Object? jsonSafe(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries) entry.key.toString(): jsonSafe(entry.value),
      };
    }
    if (value is Iterable) {
      return [for (final item in value) jsonSafe(item)];
    }
    return value.toString();
  }

  AdaptLogEntry copyWith({
    String? id,
    String? message,
    AdaptLogLevel? level,
    DateTime? timestamp,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    return AdaptLogEntry(
      id: id ?? this.id,
      message: message ?? this.message,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    final extra = metadata.isEmpty ? '' : ', metadata: $metadata';
    return 'AdaptLogEntry(${level.name}, $timestamp, "$message"$extra)';
  }
}

/// Erro reconstruído de JSON: guarda o tipo original e o texto.
class AdaptLogSerializedError {
  final String type;
  final String message;

  const AdaptLogSerializedError({required this.type, required this.message});

  @override
  String toString() => message;
}
