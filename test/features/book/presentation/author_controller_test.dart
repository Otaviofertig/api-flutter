import 'package:flutter_test/flutter_test.dart';
import 'package:libria/core/error/failures.dart';
import 'package:libria/core/error/result.dart';
import 'package:libria/core/state/ui_state.dart';
import 'package:libria/features/book/domain/entities/author.dart';
import 'package:libria/features/book/domain/entities/book.dart';
import 'package:libria/features/book/domain/usecases/get_author.dart';
import 'package:libria/features/book/domain/usecases/get_author_works.dart';
import 'package:libria/features/book/presentation/controllers/author_controller.dart';

class _FakeGetAuthor implements GetAuthor {
  _FakeGetAuthor(this.response);

  Result<Author> response;
  int calls = 0;

  @override
  Future<Result<Author>> call(String authorId) async {
    calls++;
    return response;
  }
}

class _FakeGetAuthorWorks implements GetAuthorWorks {
  _FakeGetAuthorWorks(this.responses);

  final List<Result<List<Book>>> responses;
  final List<AuthorWorksParams> calls = <AuthorWorksParams>[];

  @override
  Future<Result<List<Book>>> call(AuthorWorksParams params) async {
    final int index = calls.length;
    calls.add(params);
    return responses[index.clamp(0, responses.length - 1)];
  }
}

Book _book(String id) => Book(id: id, title: 'Obra $id');

List<Book> _page(int size, {String prefix = 'a'}) =>
    List<Book>.generate(size, (int i) => _book('$prefix$i'));

const Author _tolkien = Author(id: 'OL26320A', name: 'J.R.R. Tolkien');

void main() {
  AuthorController build(
    _FakeGetAuthor author,
    _FakeGetAuthorWorks works, {
    int pageSize = 5,
  }) {
    return AuthorController(
      author,
      works,
      authorId: 'OL26320A',
      authorName: 'Tolkien (da busca)',
      pageSize: pageSize,
    );
  }

  group('AuthorController', () {
    test('carrega ficha e obras, cada uma no seu estado', () async {
      final _FakeGetAuthor author = _FakeGetAuthor(const Ok<Author>(_tolkien));
      final _FakeGetAuthorWorks works =
          _FakeGetAuthorWorks(<Result<List<Book>>>[Ok<List<Book>>(_page(3))]);
      final AuthorController controller = build(author, works);

      await controller.load();

      expect(controller.author, isA<SuccessState<Author>>());
      expect(controller.works, isA<SuccessState<List<Book>>>());
      expect(controller.works.dataOrNull, hasLength(3));
      // Página incompleta encerra a paginação.
      expect(controller.hasMore, isFalse);
    });

    test('o nome da ficha substitui o herdado quando chega', () async {
      final _FakeGetAuthor author = _FakeGetAuthor(const Ok<Author>(_tolkien));
      final AuthorController controller = build(
        author,
        _FakeGetAuthorWorks(<Result<List<Book>>>[const Ok<List<Book>>(<Book>[])]),
      );

      expect(controller.displayName, 'Tolkien (da busca)');

      await controller.loadAuthor();

      expect(controller.displayName, 'J.R.R. Tolkien');
    });

    test('falha na ficha não derruba a bibliografia', () async {
      final _FakeGetAuthor author =
          _FakeGetAuthor(const Err<Author>(NetworkFailure()));
      final _FakeGetAuthorWorks works =
          _FakeGetAuthorWorks(<Result<List<Book>>>[Ok<List<Book>>(_page(2))]);
      final AuthorController controller = build(author, works);

      await controller.load();

      expect(controller.author, isA<ErrorState<Author>>());
      expect(controller.works, isA<SuccessState<List<Book>>>());
      // O nome herdado da tela anterior segura a página.
      expect(controller.displayName, 'Tolkien (da busca)');
    });

    test('autor sem obras vira estado vazio', () async {
      final AuthorController controller = build(
        _FakeGetAuthor(const Ok<Author>(_tolkien)),
        _FakeGetAuthorWorks(<Result<List<Book>>>[const Ok<List<Book>>(<Book>[])]),
      );

      await controller.loadWorks();

      expect(controller.works, isA<EmptyState<List<Book>>>());
      expect(controller.hasMore, isFalse);
    });

    test('página cheia habilita paginação e concatena sem duplicar', () async {
      final _FakeGetAuthorWorks works = _FakeGetAuthorWorks(<Result<List<Book>>>[
        Ok<List<Book>>(_page(5)),
        // A segunda página repete 'a4' — o endpoint faz isso quando o acervo
        // muda entre as chamadas.
        Ok<List<Book>>(<Book>[_book('a4'), _book('b0'), _book('b1')]),
      ]);
      final AuthorController controller =
          build(_FakeGetAuthor(const Ok<Author>(_tolkien)), works);

      await controller.loadWorks();
      expect(controller.hasMore, isTrue);

      await controller.loadMore();

      expect(works.calls.map((AuthorWorksParams p) => p.page), <int>[1, 2]);
      expect(controller.works.dataOrNull, hasLength(7));
      expect(controller.hasMore, isFalse);
      expect(controller.isLoadingMore, isFalse);
    });

    test('falha ao paginar preserva o que já está na tela', () async {
      final _FakeGetAuthorWorks works = _FakeGetAuthorWorks(<Result<List<Book>>>[
        Ok<List<Book>>(_page(5)),
        const Err<List<Book>>(NetworkFailure()),
      ]);
      final AuthorController controller =
          build(_FakeGetAuthor(const Ok<Author>(_tolkien)), works);

      await controller.loadWorks();
      await controller.loadMore();

      expect(controller.works.dataOrNull, hasLength(5));
      expect(controller.hasMore, isFalse);
    });

    test('as obras levam o nome do autor, que o endpoint não repete', () async {
      final _FakeGetAuthorWorks works =
          _FakeGetAuthorWorks(<Result<List<Book>>>[Ok<List<Book>>(_page(1))]);
      final AuthorController controller =
          build(_FakeGetAuthor(const Ok<Author>(_tolkien)), works);

      await controller.loadWorks();

      expect(works.calls.single.authorName, 'Tolkien (da busca)');
      expect(works.calls.single.authorId, 'OL26320A');
    });

    test('loadMore sem página anterior não chama a API', () async {
      final _FakeGetAuthorWorks works =
          _FakeGetAuthorWorks(<Result<List<Book>>>[Ok<List<Book>>(_page(1))]);
      final AuthorController controller =
          build(_FakeGetAuthor(const Ok<Author>(_tolkien)), works);

      await controller.loadMore();

      expect(works.calls, isEmpty);
    });
  });
}
