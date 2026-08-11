import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/book.dart';
import '../repositories/book_repository.dart';

final class SearchBooksParams {
  const SearchBooksParams({required this.query, this.page = 1});

  final String query;
  final int page;

  String get normalizedQuery => query.trim();
  bool get isValid => normalizedQuery.length >= minQueryLength;

  static const int minQueryLength = 2;
}

/// Busca livros por título, autor ou ISBN.
///
/// A regra "termo mínimo" mora aqui, não na UI: qualquer tela que use este
/// caso de uso herda a mesma validação.
// Não é `final`: casos de uso precisam ser implementáveis por dublês de teste.
class SearchBooks implements UseCase<List<Book>, SearchBooksParams> {
  const SearchBooks(this._repository);

  final IBookRepository _repository;

  @override
  Future<Result<List<Book>>> call(SearchBooksParams params) async {
    if (!params.isValid) {
      return const Err<List<Book>>(
        ValidationFailure('Digite ao menos 2 caracteres para buscar.'),
      );
    }

    return _repository.searchBooks(query: params.normalizedQuery, page: params.page);
  }
}
