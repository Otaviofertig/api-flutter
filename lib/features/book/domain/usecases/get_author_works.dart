import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/book.dart';
import '../repositories/author_repository.dart';

final class AuthorWorksParams {
  const AuthorWorksParams({
    required this.authorId,
    required this.authorName,
    this.page = 1,
    this.limit,
  });

  final String authorId;

  /// Nome já conhecido pela tela; entra nos livros porque o endpoint de obras
  /// não repete o autor em cada registro.
  final String authorName;

  final int page;
  final int? limit;
}

/// Obras de um autor, paginadas.
// Não é `final`: casos de uso precisam ser implementáveis por dublês de teste.
class GetAuthorWorks implements UseCase<List<Book>, AuthorWorksParams> {
  const GetAuthorWorks(this._repository);

  final IAuthorRepository _repository;

  @override
  Future<Result<List<Book>>> call(AuthorWorksParams params) async {
    if (params.authorId.trim().isEmpty) {
      return const Err<List<Book>>(ValidationFailure('Autor não identificado.'));
    }

    return _repository.getAuthorWorks(
      authorId: params.authorId.trim(),
      authorName: params.authorName,
      page: params.page,
      limit: params.limit,
    );
  }
}
