import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/book.dart';
import '../repositories/book_repository.dart';

/// Adiciona ou remove um livro da estante e devolve o **novo** estado
/// (`true` = passou a ser favorito).
final class ToggleFavorite implements UseCase<bool, Book> {
  const ToggleFavorite(this._repository);

  final IFavoriteRepository _repository;

  @override
  Future<Result<bool>> call(Book params) async {
    final Result<bool> current = await _repository.isFavorite(params.id);

    return switch (current) {
      Err<bool>(:final failure) => Err<bool>(failure),
      Ok<bool>(value: final bool isFav) => await _apply(params, isFav),
    };
  }

  Future<Result<bool>> _apply(Book book, bool isFavorite) async {
    final Result<void> operation =
        isFavorite ? await _repository.removeFavorite(book.id) : await _repository.addFavorite(book);

    return operation.map((_) => !isFavorite);
  }
}
