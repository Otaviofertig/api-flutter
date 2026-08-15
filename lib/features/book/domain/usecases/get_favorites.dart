import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/shelf_entry.dart';
import '../repositories/book_repository.dart';

/// Lista a "Minha Estante", cada livro com o seu status de leitura.
class GetFavorites implements NoParamsUseCase<List<ShelfEntry>> {
  const GetFavorites(this._repository);

  final IFavoriteRepository _repository;

  @override
  Future<Result<List<ShelfEntry>>> call() => _repository.getFavorites();
}
