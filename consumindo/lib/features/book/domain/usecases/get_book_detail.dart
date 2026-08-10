import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/book.dart';
import '../entities/book_detail.dart';
import '../repositories/book_repository.dart';

final class GetBookDetailParams {
  const GetBookDetailParams({required this.workId, this.fallback});

  final String workId;

  /// Livro da listagem, usado para completar autores/ano ausentes no detalhe.
  final Book? fallback;
}

/// Carrega os detalhes de uma obra da Open Library.
final class GetBookDetail implements UseCase<BookDetail, GetBookDetailParams> {
  const GetBookDetail(this._repository);

  final IBookRepository _repository;

  @override
  Future<Result<BookDetail>> call(GetBookDetailParams params) {
    return _repository.getBookDetail(workId: params.workId, fallback: params.fallback);
  }
}
