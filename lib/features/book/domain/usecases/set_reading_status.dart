import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/book.dart';
import '../entities/reading_status.dart';
import '../repositories/book_repository.dart';

final class SetReadingStatusParams {
  const SetReadingStatusParams({required this.book, required this.status});

  final Book book;
  final ReadingStatus status;
}

/// Marca em que ponto da leitura um livro está.
///
/// Se o livro ainda não estiver na estante, ele entra já com o status pedido:
/// marcar "Lendo" num livro que se acabou de encontrar é um jeito legítimo de
/// salvá-lo, e exigir "adicionar" antes seria burocracia.
// Não é `final`: casos de uso precisam ser implementáveis por dublês de teste.
class SetReadingStatus implements UseCase<ReadingStatus, SetReadingStatusParams> {
  const SetReadingStatus(this._repository);

  final IFavoriteRepository _repository;

  @override
  Future<Result<ReadingStatus>> call(SetReadingStatusParams params) async {
    final Result<bool> saved = await _repository.isFavorite(params.book.id);

    return switch (saved) {
      Err<bool>(:final failure) => Err<ReadingStatus>(failure),
      Ok<bool>(value: final bool isSaved) => await _apply(params, isSaved: isSaved),
    };
  }

  Future<Result<ReadingStatus>> _apply(
    SetReadingStatusParams params, {
    required bool isSaved,
  }) async {
    final Result<void> operation = isSaved
        ? await _repository.setStatus(bookId: params.book.id, status: params.status)
        : await _repository.addFavorite(params.book, status: params.status);

    return operation.map((_) => params.status);
  }
}
