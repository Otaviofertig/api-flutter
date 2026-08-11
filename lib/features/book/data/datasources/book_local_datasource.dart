import '../models/book_model.dart';

/// Fonte de dados local da estante. Lança `CacheException` em caso de erro.
abstract interface class IBookLocalDataSource {
  Future<List<BookModel>> getFavorites();

  Future<void> saveFavorite(BookModel book);

  Future<void> removeFavorite(String bookId);

  Future<bool> isFavorite(String bookId);
}
