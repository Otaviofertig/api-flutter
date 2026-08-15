import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reading_status.dart';
import '../repositories/book_repository.dart';

/// Em que ponto da leitura um livro está — `null` quando ele não está na
/// estante.
///
/// Substitui a pergunta "é favorito?" com uma resposta mais informativa: estar
/// na estante passa a ser exatamente "ter um status".
class GetReadingStatus implements UseCase<ReadingStatus?, String> {
  const GetReadingStatus(this._repository);

  final IFavoriteRepository _repository;

  @override
  Future<Result<ReadingStatus?>> call(String bookId) => _repository.statusOf(bookId);
}
