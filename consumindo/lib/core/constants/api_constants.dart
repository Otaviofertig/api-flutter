import '../config/app_config.dart';

/// Endpoints e helpers da Open Library API.
///
/// As URLs vêm de [AppConfig] (arquivo `.env`), com fallback para os valores
/// públicos oficiais — trocar de ambiente não exige recompilar código.
///
/// Documentação: https://openlibrary.org/developers/api
abstract final class ApiConstants {
  static String get baseUrl => AppConfig.instance.apiBaseUrl;
  static String get coversBaseUrl => AppConfig.instance.coversBaseUrl;

  /// Campos solicitados na busca — reduz drasticamente o payload da resposta.
  static const String searchFields =
      'key,title,author_name,first_publish_year,cover_i,edition_count,ia';

  static int get searchPageSize => AppConfig.instance.searchPageSize;
  static Duration get requestTimeout => AppConfig.instance.requestTimeout;

  /// `GET /search.json?q=...`
  static Uri search({required String query, int page = 1, int? limit}) {
    return Uri.parse('$baseUrl/search.json').replace(
      queryParameters: <String, String>{
        'q': query,
        'fields': searchFields,
        'limit': '${limit ?? searchPageSize}',
        'page': '$page',
      },
    );
  }

  /// `GET /works/{id}.json` — [workId] aceita tanto `OL45804W` quanto `/works/OL45804W`.
  static Uri work(String workId) {
    final String id = normalizeWorkId(workId);
    return Uri.parse('$baseUrl/works/$id.json');
  }

  /// Remove o prefixo `/works/` retornado pelo campo `key` da busca.
  static String normalizeWorkId(String rawKey) {
    final String trimmed = rawKey.trim();
    if (trimmed.startsWith('/works/')) return trimmed.substring('/works/'.length);
    if (trimmed.startsWith('works/')) return trimmed.substring('works/'.length);
    return trimmed;
  }

  /// URL da capa pelo id numérico. [size]: `S`, `M` ou `L`.
  static String? coverById(int? coverId, {String size = 'M'}) {
    if (coverId == null || coverId <= 0) return null;
    return '$coversBaseUrl/b/id/$coverId-$size.jpg';
  }
}
