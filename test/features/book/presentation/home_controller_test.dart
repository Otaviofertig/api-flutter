import 'package:libria/core/error/failures.dart';
import 'package:libria/core/error/result.dart';
import 'package:libria/core/state/ui_state.dart';
import 'package:libria/core/utils/debouncer.dart';
import 'package:libria/features/book/domain/entities/book.dart';
import 'package:libria/features/book/domain/usecases/search_books.dart';
import 'package:libria/features/book/presentation/controllers/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dublê do caso de uso: devolve respostas programadas, com atraso opcional
/// para simular requisições que voltam fora de ordem.
class _FakeSearchBooks implements SearchBooks {
  _FakeSearchBooks(this.responses);

  final List<Result<List<Book>>> responses;
  final List<SearchBooksParams> calls = <SearchBooksParams>[];
  Duration Function(int callIndex)? delayFor;

  @override
  Future<Result<List<Book>>> call(SearchBooksParams params) async {
    final int index = calls.length;
    calls.add(params);

    final Duration delay = delayFor?.call(index) ?? Duration.zero;
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    return responses[index.clamp(0, responses.length - 1)];
  }
}

Book _book(String id) => Book(id: id, title: 'Livro $id');

List<Book> _page(int size, {String prefix = 'a'}) =>
    List<Book>.generate(size, (int i) => _book('$prefix$i'));

void main() {
  const Duration debounce = Duration(milliseconds: 50);

  HomeController build(_FakeSearchBooks fake, {int pageSize = 20}) => HomeController(
        fake,
        debouncer: Debouncer(duration: debounce),
        pageSize: pageSize,
      );

  test('digitação sucessiva dispara uma única busca (debounce)', () async {
    final _FakeSearchBooks fake = _FakeSearchBooks(<Result<List<Book>>>[
      Ok<List<Book>>(_page(3)),
    ]);
    final HomeController controller = build(fake);

    controller.onQueryChanged('t');
    controller.onQueryChanged('to');
    controller.onQueryChanged('tolkien');

    await Future<void>.delayed(debounce * 3);

    expect(fake.calls.length, 1);
    expect(fake.calls.single.query, 'tolkien');
    expect(controller.state, isA<SuccessState<List<Book>>>());

    controller.dispose();
  });

  test('resposta obsoleta não sobrescreve a busca mais recente', () async {
    final _FakeSearchBooks fake = _FakeSearchBooks(<Result<List<Book>>>[
      Ok<List<Book>>(_page(1, prefix: 'antiga')),
      Ok<List<Book>>(_page(2, prefix: 'nova')),
    ])
      // A primeira busca demora bem mais que a segunda.
      ..delayFor = (int i) => i == 0 ? const Duration(milliseconds: 120) : Duration.zero;

    final HomeController controller = build(fake);

    final Future<void> lenta = controller.searchNow('lenta');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await controller.searchNow('rápida');

    // Só então a resposta atrasada da primeira busca chega.
    await lenta;

    final List<Book>? books = controller.state.dataOrNull;
    expect(books, isNotNull);
    expect(books!.first.id, startsWith('nova'));

    controller.dispose();
  });

  test('busca sem resultados vira estado vazio', () async {
    final _FakeSearchBooks fake = _FakeSearchBooks(<Result<List<Book>>>[
      const Ok<List<Book>>(<Book>[]),
    ]);
    final HomeController controller = build(fake);

    await controller.searchNow('asdfghjkl');

    expect(controller.state, isA<EmptyState<List<Book>>>());
    controller.dispose();
  });

  test('falha de rede vira estado de erro com a mensagem do Failure', () async {
    final _FakeSearchBooks fake = _FakeSearchBooks(<Result<List<Book>>>[
      const Err<List<Book>>(NetworkFailure()),
    ]);
    final HomeController controller = build(fake);

    await controller.searchNow('tolkien');

    final UiState<List<Book>> state = controller.state;
    expect(state, isA<ErrorState<List<Book>>>());
    expect((state as ErrorState<List<Book>>).failure, isA<NetworkFailure>());

    controller.dispose();
  });

  test('paginação concatena a próxima página e ignora duplicatas', () async {
    final _FakeSearchBooks fake = _FakeSearchBooks(<Result<List<Book>>>[
      Ok<List<Book>>(_page(2, prefix: 'p1')),
      // A API repete o primeiro item da página anterior.
      Ok<List<Book>>(<Book>[_book('p10'), _book('p2a'), _book('p2b')]),
    ]);
    final HomeController controller = build(fake, pageSize: 2);

    await controller.searchNow('tolkien');
    expect(controller.hasMore, isTrue);

    await controller.loadMore();

    final List<Book> books = controller.state.dataOrNull!;
    expect(books.map((Book b) => b.id), <String>['p10', 'p11', 'p2a', 'p2b']);
    expect(fake.calls.last.page, 2);

    controller.dispose();
  });

  test('limpar a busca volta ao estado inicial', () async {
    final _FakeSearchBooks fake = _FakeSearchBooks(<Result<List<Book>>>[
      Ok<List<Book>>(_page(3)),
    ]);
    final HomeController controller = build(fake);

    await controller.searchNow('tolkien');
    controller.clear();

    expect(controller.state, isA<IdleState<List<Book>>>());
    expect(controller.query, isEmpty);

    controller.dispose();
  });
}
