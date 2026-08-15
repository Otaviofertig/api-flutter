import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_local_datasource.dart';
import '../models/book_model.dart';

/// Implementação de [IFavoriteRepository] sobre a fonte local.
final class FavoriteRepositoryImpl implements IFavoriteRepository {
  const FavoriteRepositoryImpl(this._local);

  final IBookLocalDataSource _local;

  @override
  Future<Result<List<ShelfEntry>>> getFavorites() {
    return _guard<List<ShelfEntry>>(() async => await _local.getFavorites());
  }

  @override
  Future<Result<void>> addFavorite(
    Book book, {
    ReadingStatus status = ReadingStatus.initial,
  }) {
    return _guard<void>(
      () => _local.saveFavorite(BookModel.fromEntity(book), status: status),
    );
  }

  @override
  Future<Result<void>> removeFavorite(String bookId) {
    return _guard<void>(() => _local.removeFavorite(bookId));
  }

  @override
  Future<Result<bool>> isFavorite(String bookId) {
    return _guard<bool>(() => _local.isFavorite(bookId));
  }

  @override
  Future<Result<void>> setStatus({
    required String bookId,
    required ReadingStatus status,
  }) {
    return _guard<void>(() => _local.setStatus(bookId, status));
  }

  @override
  Future<Result<ReadingStatus?>> statusOf(String bookId) {
    return _guard<ReadingStatus?>(() => _local.statusOf(bookId));
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok<T>(await action());
    } on AppException catch (e) {
      return Err<T>(Failure.fromException(e));
    } catch (_) {
      return Err<T>(const CacheFailure());
    }
  }
}
