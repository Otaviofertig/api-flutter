import 'package:consumindo/core/error/failures.dart';
import 'package:consumindo/core/error/result.dart';
import 'package:consumindo/core/state/ui_state.dart';
import 'package:consumindo/features/book/domain/entities/book.dart';
import 'package:consumindo/features/book/domain/usecases/get_favorites.dart';
import 'package:consumindo/features/book/domain/usecases/toggle_favorite.dart';
import 'package:consumindo/features/book/presentation/controllers/favorites_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGetFavorites implements GetFavorites {
  _FakeGetFavorites(this.result);

  Result<List<Book>> result;

  @override
  Future<Result<List<Book>>> call() async => result;
}

class _FakeToggleFavorite implements ToggleFavorite {
  _FakeToggleFavorite(this.result);

  Result<bool> result;
  final List<Book> calls = <Book>[];

  @override
  Future<Result<bool>> call(Book params) async {
    calls.add(params);
    return result;
  }
}

const Book _dune = Book(id: 'OL1W', title: 'Duna');
const Book _hobbit = Book(id: 'OL2W', title: 'O Hobbit');

void main() {
  test('estante sem livros vira estado vazio', () async {
    final FavoritesController controller = FavoritesController(
      _FakeGetFavorites(const Ok<List<Book>>(<Book>[])),
      _FakeToggleFavorite(const Ok<bool>(false)),
    );

    await controller.load();

    expect(controller.state, isA<EmptyState<List<Book>>>());
    controller.dispose();
  });

  test('remover tira o livro da lista e chama o caso de uso', () async {
    final _FakeToggleFavorite toggle = _FakeToggleFavorite(const Ok<bool>(false));
    final FavoritesController controller = FavoritesController(
      _FakeGetFavorites(const Ok<List<Book>>(<Book>[_dune, _hobbit])),
      toggle,
    );

    await controller.load();
    final String message = await controller.remove(_dune);

    expect(controller.state.dataOrNull, <Book>[_hobbit]);
    expect(toggle.calls.single.id, _dune.id);
    expect(message, contains('Duna'));

    controller.dispose();
  });

  test('falha ao remover devolve o livro para a lista', () async {
    final FavoritesController controller = FavoritesController(
      _FakeGetFavorites(const Ok<List<Book>>(<Book>[_dune, _hobbit])),
      _FakeToggleFavorite(const Err<bool>(CacheFailure())),
    );

    await controller.load();
    final String message = await controller.remove(_dune);

    expect(controller.state.dataOrNull, <Book>[_dune, _hobbit]);
    expect(message, const CacheFailure().message);

    controller.dispose();
  });
}
