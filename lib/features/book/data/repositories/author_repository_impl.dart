import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/author_repository.dart';
import '../datasources/author_remote_datasource.dart';

/// Implementação de [IAuthorRepository]: fronteira entre exceções e `Failure`.
final class AuthorRepositoryImpl implements IAuthorRepository {
  const AuthorRepositoryImpl(this._remote);

  final IAuthorRemoteDataSource _remote;

  @override
  Future<Result<Author>> getAuthor(String authorId) {
    return _guard<Author>(() => _remote.getAuthor(authorId));
  }

  @override
  Future<Result<List<Book>>> getAuthorWorks({
    required String authorId,
    required String authorName,
    int page = 1,
    int? limit,
  }) {
    return _guard<List<Book>>(
      () => _remote.getAuthorWorks(
        authorId: authorId,
        authorName: authorName,
        page: page,
        limit: limit,
      ),
    );
  }

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
