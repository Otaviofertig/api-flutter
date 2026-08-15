import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/http_client.dart';
import '../models/author_model.dart';
import '../models/book_model.dart';
import 'author_remote_datasource.dart';

/// Implementação HTTP da fonte de autores.
final class AuthorRemoteDataSourceImpl implements IAuthorRemoteDataSource {
  const AuthorRemoteDataSourceImpl(this._client);

  final IHttpClient _client;

  @override
  Future<AuthorModel> getAuthor(String authorId) async {
    final dynamic json = await _client.getJson(ApiConstants.author(authorId));

    if (json is! Map<String, dynamic>) throw const ParseException();

    // O id normalizado entra como fallback: registros redirecionados devolvem
    // uma `key` diferente da pedida, e a tela precisa do id que ela conhece.
    return AuthorModel.fromJson(json, fallbackId: authorId);
  }

  @override
  Future<List<BookModel>> getAuthorWorks({
    required String authorId,
    required String authorName,
    int page = 1,
    int? limit,
  }) async {
    // Resolver o tamanho aqui mantém `offset` e `limit` coerentes: passar
    // `limit` nulo adiante faria a URL usar o padrão do .env enquanto o
    // offset seria calculado com outro número.
    final int size = limit ?? ApiConstants.searchPageSize;
    final int offset = (page < 1 ? 0 : page - 1) * size;

    final dynamic json = await _client.getJson(
      ApiConstants.authorWorks(authorId, offset: offset, limit: size),
    );

    if (json is! Map<String, dynamic>) throw const ParseException();

    final Object? entries = json['entries'];
    if (entries is! List) throw const ParseException();

    return entries
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> entry) => BookModel.fromAuthorWorkJson(
              entry,
              authorId: ApiConstants.normalizeAuthorId(authorId),
              authorName: authorName,
            ))
        // Sem `key` não há como abrir o detalhe: descartamos o registro.
        .where((BookModel book) => book.id.isNotEmpty)
        .toList(growable: false);
  }
}
