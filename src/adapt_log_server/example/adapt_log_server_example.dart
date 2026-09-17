import 'package:adapt_log_server/adapt_log_server.dart';

Future<void> main() async {
  final server = AdaptLogServer(
    port: 8080,
    dbPath: 'adapt_log.sqlite',
    apiKeys: {'dev-key': 'meu-app'},
  );
  await server.start();
  print('painel em ${server.url}  |  chave: dev-key');
}
