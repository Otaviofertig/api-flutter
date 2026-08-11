import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração da aplicação lida do arquivo `.env` (não versionado).
///
/// ⚠️ Importante: em um app Flutter o `.env` é embarcado como asset e viaja
/// dentro do APK/IPA. Ele mantém credenciais fora do controle de versão e
/// permite trocar ambiente sem recompilar código, mas **não** é um cofre:
/// qualquer pessoa com o binário consegue lê-lo. Segredos de verdade
/// (chaves de escrita, tokens de terceiros) devem viver em um backend.
///
/// Todos os valores têm fallback: rodar sem `.env` continua funcionando,
/// porque a Open Library é pública e não exige autenticação para leitura.
final class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.coversBaseUrl,
    required this.contactEmail,
    required this.requestTimeout,
    required this.searchPageSize,
    this.accessKey,
    this.secretKey,
  });

  /// Monta a configuração a partir das variáveis já carregadas por [dotenv].
  factory AppConfig.fromEnv() {
    return AppConfig(
      apiBaseUrl: _string('OPENLIBRARY_BASE_URL', 'https://openlibrary.org'),
      coversBaseUrl: _string('OPENLIBRARY_COVERS_URL', 'https://covers.openlibrary.org'),
      contactEmail: _string('OPENLIBRARY_CONTACT_EMAIL', 'contato@libria.app'),
      requestTimeout: Duration(seconds: _int('REQUEST_TIMEOUT_SECONDS', 20)),
      searchPageSize: _int('SEARCH_PAGE_SIZE', 20),
      accessKey: _optional('OPENLIBRARY_ACCESS_KEY'),
      secretKey: _optional('OPENLIBRARY_SECRET_KEY'),
    );
  }

  final String apiBaseUrl;
  final String coversBaseUrl;

  /// Identificação exigida pelas boas práticas de uso da Open Library.
  final String contactEmail;

  final Duration requestTimeout;
  final int searchPageSize;

  /// Credenciais S3-like da Open Library — necessárias apenas nos endpoints
  /// de escrita/importação. Ausentes por padrão: o Libria é somente leitura.
  final String? accessKey;
  final String? secretKey;

  bool get hasCredentials =>
      (accessKey?.isNotEmpty ?? false) && (secretKey?.isNotEmpty ?? false);

  String get userAgent => 'Libria/1.0 (Flutter; $contactEmail)';

  /// Cabeçalhos enviados em toda requisição; a autenticação (HTTP Basic) só
  /// entra quando as credenciais existem no `.env`.
  Map<String, String> get headers => <String, String>{
        'Accept': 'application/json',
        'User-Agent': userAgent,
        if (hasCredentials)
          'Authorization': 'Basic ${base64Encode(utf8.encode('$accessKey:$secretKey'))}',
      };

  // --- Bootstrap -------------------------------------------------------------

  static AppConfig? _instance;

  /// Configuração corrente. Chame [load] antes (feito no `main`).
  static AppConfig get instance => _instance ?? const AppConfig.fallback();

  /// Carrega o `.env` e materializa a configuração.
  ///
  /// O arquivo é opcional de propósito: em CI, ou num clone recém-feito sem
  /// `.env`, o app sobe com os valores públicos padrão em vez de quebrar.
  static Future<AppConfig> load({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
      _instance = AppConfig.fromEnv();
    } catch (_) {
      _instance = const AppConfig.fallback();
    }
    return _instance!;
  }

  /// Valores públicos padrão, usados quando não há `.env`.
  const AppConfig.fallback()
      : apiBaseUrl = 'https://openlibrary.org',
        coversBaseUrl = 'https://covers.openlibrary.org',
        contactEmail = 'contato@libria.app',
        requestTimeout = const Duration(seconds: 20),
        searchPageSize = 20,
        accessKey = null,
        secretKey = null;

  // --- Leitura defensiva do .env ---------------------------------------------

  static String _string(String key, String fallback) {
    final String? value = _optional(key);
    return value ?? fallback;
  }

  static int _int(String key, int fallback) {
    return int.tryParse(_optional(key) ?? '') ?? fallback;
  }

  static String? _optional(String key) {
    if (!dotenv.isInitialized) return null;
    final String? value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
