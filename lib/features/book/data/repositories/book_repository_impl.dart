import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_datasource.dart';

/// Implementação de [IBookRepository]: fronteira entre exceções e `Failure`.
final class BookRepositoryImpl implements IBookRepository {
  const BookRepositoryImpl(this._remote);

  final IBookRemoteDataSource _remote;

  @override
  Future<Result<List<Book>>> searchBooks({required String query, int page = 1}) async {
    return _guard<List<Book>>(() async {
      final List<Book> books = await _remote.searchBooks(query: query, page: page);
      return books;
    });
  }

  @override
  Future<Result<List<Book>>> getTrending({String period = 'daily', int? limit}) async {
    return _guard<List<Book>>(() => _remote.getTrending(period: period, limit: limit));
  }

  @override
  Future<Result<BookDetail>> getBookDetail({required String workId, Book? fallback}) async {
    return _guard<BookDetail>(
      () => _remote.getBookDetail(workId: workId, fallback: fallback),
    );
  }

  /// Executa [action] convertendo qualquer exceção no `Failure` correspondente.
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok<T>(await action());
    } on AppException catch (e) {
      return Err<T>(Failure.fromException(e));
    } catch (_) {
      return Err<T>(const UnexpectedFailure());
    }
  }
}
