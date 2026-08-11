import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/book_repository.dart';

/// Verifica se uma obra já está na estante (usado na tela de detalhes).
class IsFavorite implements UseCase<bool, String> {
  const IsFavorite(this._repository);

  final IFavoriteRepository _repository;

  @override
  Future<Result<bool>> call(String params) => _repository.isFavorite(params);
}
