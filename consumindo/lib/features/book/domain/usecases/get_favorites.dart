import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/book.dart';
import '../repositories/book_repository.dart';

/// Lista os livros salvos na "Minha Estante".
final class GetFavorites implements NoParamsUseCase<List<Book>> {
  const GetFavorites(this._repository);

  final IFavoriteRepository _repository;

  @override
  Future<Result<List<Book>>> call() => _repository.getFavorites();
}
