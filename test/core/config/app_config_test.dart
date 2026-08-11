import 'dart:convert';

import 'package:libria/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('sem .env carregado, cai nos valores públicos padrão', () {
      const AppConfig config = AppConfig.fallback();

      expect(config.apiBaseUrl, 'https://openlibrary.org');
      expect(config.coversBaseUrl, 'https://covers.openlibrary.org');
      expect(config.requestTimeout, const Duration(seconds: 20));
      expect(config.hasCredentials, isFalse);
    });

    test('não envia Authorization quando não há credenciais', () {
      const AppConfig config = AppConfig.fallback();

      expect(config.headers.containsKey('Authorization'), isFalse);
      expect(config.headers['User-Agent'], contains('Libria/1.0'));
    });

    test('envia HTTP Basic quando as credenciais existem no .env', () {
      const AppConfig config = AppConfig(
        apiBaseUrl: 'https://openlibrary.org',
        coversBaseUrl: 'https://covers.openlibrary.org',
        contactEmail: 'time@libria.app',
        requestTimeout: Duration(seconds: 5),
        searchPageSize: 10,
        accessKey: 'chave',
        secretKey: 'segredo',
      );

      expect(config.hasCredentials, isTrue);
      expect(
        config.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('chave:segredo'))}',
      );
      expect(config.userAgent, contains('time@libria.app'));
    });
  });
}
