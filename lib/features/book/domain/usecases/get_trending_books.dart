import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/book.dart';
import '../repositories/book_repository.dart';

final class TrendingParams {
  const TrendingParams({this.period = daily, this.limit});

  /// Janela do ranking: `now`, `daily`, `weekly`, `monthly`, `yearly` ou
  /// `forever`. Valor desconhecido cai em `daily` na montagem da URL.
  final String period;

  /// Quantas obras trazer. `null` usa o tamanho de página do `.env`.
  final int? limit;

  static const String daily = 'daily';
}

/// Obras em alta na Open Library.
///
/// A Home usa isso como vitrine enquanto ninguém digitou nada: uma tela de
/// busca vazia não convida a explorar acervo nenhum.
// Não é `final`: casos de uso precisam ser implementáveis por dublês de teste.
class GetTrendingBooks implements UseCase<List<Book>, TrendingParams> {
  const GetTrendingBooks(this._repository);

  final IBookRepository _repository;

  @override
  Future<Result<List<Book>>> call(TrendingParams params) {
    return _repository.getTrending(period: params.period, limit: params.limit);
  }
}
