import '../models/author_model.dart';
import '../models/book_model.dart';

/// Fonte remota de autores (Open Library). Lança `AppException` em erro.
abstract interface class IAuthorRemoteDataSource {
  Future<AuthorModel> getAuthor(String authorId);

  /// Obras do autor. [authorName] entra nos livros devolvidos porque o
  /// endpoint de obras não repete o nome em cada registro.
  ///
  /// Recebe [page] (base 1), não `offset`: a conversão depende do tamanho de
  /// página, que é detalhe da API e mora na implementação.
  Future<List<BookModel>> getAuthorWorks({
    required String authorId,
    required String authorName,
    int page,
    int? limit,
  });
}
