import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/http_client.dart';
import '../../domain/entities/book.dart';
import '../models/book_detail_model.dart';
import '../models/book_model.dart';
import 'book_remote_datasource.dart';

/// Implementação HTTP da fonte remota.
///
/// Responsabilidade única: falar com a API e devolver models. Não decide
/// política de erro nem de cache — isso é do repositório.
final class BookRemoteDataSourceImpl implements IBookRemoteDataSource {
  const BookRemoteDataSourceImpl(this._client);

  final IHttpClient _client;

  @override
  Future<List<BookModel>> searchBooks({required String query, int page = 1}) async {
    final dynamic json = await _client.getJson(
      ApiConstants.search(query: query, page: page),
    );

    if (json is! Map<String, dynamic>) throw const ParseException();

    final Object? docs = json['docs'];
    if (docs is! List) throw const ParseException();

    return docs
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromSearchJson)
        // Sem `key` não há como abrir o detalhe: descartamos o registro.
        .where((BookModel book) => book.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<BookModel>> getTrending({String period = 'daily', int? limit}) async {
    final dynamic json = await _client.getJson(
      ApiConstants.trending(period: period, limit: limit),
    );

    if (json is! Map<String, dynamic>) throw const ParseException();

    // A lista vem em `works`, não em `docs` — o resto do formato é idêntico
    // ao da busca, então o mesmo parser serve.
    final Object? works = json['works'];
    if (works is! List) throw const ParseException();

    return works
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromSearchJson)
        .where((BookModel book) => book.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<BookDetailModel> getBookDetail({required String workId, Book? fallback}) async {
    final dynamic json = await _client.getJson(ApiConstants.work(workId));

    if (json is! Map<String, dynamic>) throw const ParseException();

    return BookDetailModel.fromJson(json, fallback: fallback);
  }
}
