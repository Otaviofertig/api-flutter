import '../../domain/entities/book.dart';
import '../models/book_detail_model.dart';
import '../models/book_model.dart';

/// Fonte de dados remota (Open Library). Lança `AppException` em caso de erro.
abstract interface class IBookRemoteDataSource {
  Future<List<BookModel>> searchBooks({required String query, int page});

  /// Obras em alta na Open Library, para a Home sem busca digitada.
  Future<List<BookModel>> getTrending({String period, int? limit});

  Future<BookDetailModel> getBookDetail({required String workId, Book? fallback});
}
