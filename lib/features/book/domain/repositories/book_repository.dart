import '../../../../core/error/result.dart';
import '../entities/book.dart';
import '../entities/book_detail.dart';

/// Contrato de acesso a livros remotos (Open Library).
///
/// Interfaces separadas por responsabilidade (ISP): quem só lê a estante não
/// precisa depender dos métodos de rede, e vice-versa.
abstract interface class IBookRepository {
  /// Busca por título, autor ou ISBN. [page] começa em 1.
  Future<Result<List<Book>>> searchBooks({required String query, int page = 1});

  /// Obras em alta, usadas como vitrine quando não há busca digitada.
  Future<Result<List<Book>>> getTrending({String period, int? limit});

  /// Detalhes de uma obra. [fallback] preenche campos que o endpoint de
  /// detalhe não retorna (autores e ano vêm da busca).
  Future<Result<BookDetail>> getBookDetail({required String workId, Book? fallback});
}

/// Contrato da estante local (favoritos).
abstract interface class IFavoriteRepository {
  Future<Result<List<Book>>> getFavorites();

  Future<Result<void>> addFavorite(Book book);

  Future<Result<void>> removeFavorite(String bookId);

  Future<Result<bool>> isFavorite(String bookId);
}
