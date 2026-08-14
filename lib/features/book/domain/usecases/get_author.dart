import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/author.dart';
import '../repositories/author_repository.dart';

/// Ficha de um autor da Open Library.
// Não é `final`: casos de uso precisam ser implementáveis por dublês de teste.
class GetAuthor implements UseCase<Author, String> {
  const GetAuthor(this._repository);

  final IAuthorRepository _repository;

  @override
  Future<Result<Author>> call(String authorId) async {
    // A regra mora aqui, e não na tela: qualquer caminho que leve a um autor
    // herda a mesma validação de id.
    if (authorId.trim().isEmpty) {
      return const Err<Author>(ValidationFailure('Autor não identificado.'));
    }

    return _repository.getAuthor(authorId.trim());
  }
}
