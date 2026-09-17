import 'dart:io';

import 'package:adapt_log_server/adapt_log_server.dart';

/// Entrypoint configurado por variáveis de ambiente:
/// - `PORT` (padrão 8080)
/// - `HOST` (padrão 0.0.0.0)
/// - `ADAPT_LOG_DB` (padrão adapt_log.sqlite)
/// - `ADAPT_LOG_API_KEYS` no formato `chave:projeto,chave2:projeto2`
Future<void> main() async {
  final env = Platform.environment;
  final keys = <String, String>{};
  for (final pair in (env['ADAPT_LOG_API_KEYS'] ?? '').split(',')) {
    final parts = pair.split(':');
    if (parts.length == 2 && parts[0].trim().isNotEmpty) keys[parts[0].trim()] = parts[1].trim();
  }
  if (keys.isEmpty) {
    stderr.writeln('Defina ADAPT_LOG_API_KEYS=chave:projeto[,chave2:projeto2]');
    exit(64);
  }
  final server = AdaptLogServer(
    port: int.tryParse(env['PORT'] ?? '') ?? 8080,
    address: env['HOST'] ?? '0.0.0.0',
    dbPath: env['ADAPT_LOG_DB'] ?? 'adapt_log.sqlite',
    apiKeys: keys,
  );
  await server.start();
  stdout.writeln('adapt_log_server em ${server.url} (projetos: ${keys.values.toSet().join(', ')})');
  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    exit(0);
  });
}
