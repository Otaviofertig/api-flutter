import 'package:flutter_test/flutter_test.dart';
import 'package:libria/core/error/failures.dart';
import 'package:libria/core/error/result.dart';
import 'package:libria/core/state/ui_state.dart';
import 'package:libria/core/utils/debouncer.dart';
import 'package:libria/features/book/domain/entities/book.dart';
import 'package:libria/features/book/domain/usecases/get_trending_books.dart';
import 'package:libria/features/book/domain/usecases/search_books.dart';
import 'package:libria/features/book/presentation/controllers/home_controller.dart';

class _FakeSearchBooks implements SearchBooks {
  final List<SearchBooksParams> calls = <SearchBooksParams>[];
  Result<List<Book>> response = const Ok<List<Book>>(<Book>[]);

  @override
  Future<Result<List<Book>>> call(SearchBooksParams params) async {
    calls.add(params);
    return response;
  }
}

class _FakeTrending implements GetTrendingBooks {
  _FakeTrending(this.response);

  Result<List<Book>> response;
  int calls = 0;
  Duration delay = Duration.zero;

  @override
  Future<Result<List<Book>>> call(TrendingParams params) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return response;
  }
}

Book _book(String id) => Book(id: id, title: 'Livro $id');

void main() {
  const Duration debounce = Duration(milliseconds: 20);

  HomeController build(_FakeSearchBooks search, [_FakeTrending? trending]) {
    return HomeController(
      search,
      trendingBooks: trending,
      debouncer: Debouncer(duration: debounce),
      pageSize: 20,
    );
  }

  group('destaques da Home', () {
    test('carrega a vitrine e expõe como sucesso', () async {
      final _FakeTrending trending =
          _FakeTrending(Ok<List<Book>>(<Book>[_book('a'), _book('b')]));
      final HomeController controller = build(_FakeSearchBooks(), trending);

      await controller.loadHighlights();

      expect(trending.calls, 1);
      expect(controller.highlights, isA<SuccessState<List<Book>>>());
      expect(controller.highlights.dataOrNull, hasLength(2));
      // A busca continua ociosa: a vitrine não é resultado de busca.
      expect(controller.state, isA<IdleState<List<Book>>>());
    });

    test('vitrine vazia vira estado vazio, não sucesso com lista vazia', () async {
      final HomeController controller =
          build(_FakeSearchBooks(), _FakeTrending(const Ok<List<Book>>(<Book>[])));

      await controller.loadHighlights();

      expect(controller.highlights, isA<EmptyState<List<Book>>>());
    });

    test('falha na vitrine não toca no estado da busca', () async {
      final HomeController controller = build(
        _FakeSearchBooks(),
        _FakeTrending(const Err<List<Book>>(NetworkFailure())),
      );

      await controller.loadHighlights();

      expect(controller.highlights, isA<ErrorState<List<Book>>>());
      // Quem abriu o app para buscar um título não leva erro por causa da
      // vitrine: a Home cai no convite de busca original.
      expect(controller.state, isA<IdleState<List<Book>>>());
    });

    test('chamada concorrente não duplica a requisição', () async {
      final _FakeTrending trending = _FakeTrending(Ok<List<Book>>(<Book>[_book('a')]))
        ..delay = const Duration(milliseconds: 40);
      final HomeController controller = build(_FakeSearchBooks(), trending);

      final Future<void> first = controller.loadHighlights();
      final Future<void> second = controller.loadHighlights();
      await Future.wait(<Future<void>>[first, second]);

      expect(trending.calls, 1);
    });

    test('sem o caso de uso injetado, a Home não tem vitrine', () async {
      final HomeController controller = build(_FakeSearchBooks());

      await controller.loadHighlights();

      expect(controller.hasHighlights, isFalse);
      expect(controller.highlights, isA<IdleState<List<Book>>>());
    });

    test('limpar a busca volta aos destaques sem ir à rede de novo', () async {
      final _FakeTrending trending = _FakeTrending(Ok<List<Book>>(<Book>[_book('a')]));
      final _FakeSearchBooks search = _FakeSearchBooks()
        ..response = Ok<List<Book>>(<Book>[_book('x')]);
      final HomeController controller = build(search, trending);

      await controller.loadHighlights();
      await controller.searchNow('tolkien');
      expect(controller.state, isA<SuccessState<List<Book>>>());

      controller.clear();

      expect(controller.state, isA<IdleState<List<Book>>>());
      // A vitrine seguiu carregada o tempo todo — nenhuma segunda chamada.
      expect(controller.highlights, isA<SuccessState<List<Book>>>());
      expect(trending.calls, 1);
    });
  });
}
