import 'package:flutter_test/flutter_test.dart';
import 'package:libria/core/error/failures.dart';
import 'package:libria/core/error/result.dart';
import 'package:libria/core/state/ui_state.dart';
import 'package:libria/features/book/domain/entities/book.dart';
import 'package:libria/features/book/domain/entities/reading_status.dart';
import 'package:libria/features/book/domain/entities/shelf_entry.dart';
import 'package:libria/features/book/domain/usecases/get_favorites.dart';
import 'package:libria/features/book/domain/usecases/set_reading_status.dart';
import 'package:libria/features/book/domain/usecases/toggle_favorite.dart';
import 'package:libria/features/book/presentation/controllers/favorites_controller.dart';

class _FakeGetFavorites implements GetFavorites {
  _FakeGetFavorites(this.result);

  Result<List<ShelfEntry>> result;

  @override
  Future<Result<List<ShelfEntry>>> call() async => result;
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

class _FakeSetStatus implements SetReadingStatus {
  _FakeSetStatus([this.failure]);

  final Failure? failure;
  final List<SetReadingStatusParams> calls = <SetReadingStatusParams>[];

  @override
  Future<Result<ReadingStatus>> call(SetReadingStatusParams params) async {
    calls.add(params);
    final Failure? error = failure;
    return error == null
        ? Ok<ReadingStatus>(params.status)
        : Err<ReadingStatus>(error);
  }
}

const Book _dune = Book(id: 'OL1W', title: 'Duna');
const Book _hobbit = Book(id: 'OL2W', title: 'O Hobbit');

const ShelfEntry _duneEntry =
    ShelfEntry(book: _dune, status: ReadingStatus.wantToRead);
const ShelfEntry _hobbitEntry = ShelfEntry(book: _hobbit, status: ReadingStatus.read);

FavoritesController _build({
  List<ShelfEntry> shelf = const <ShelfEntry>[],
  Result<bool>? toggle,
  _FakeSetStatus? setStatus,
}) {
  return FavoritesController(
    _FakeGetFavorites(Ok<List<ShelfEntry>>(shelf)),
    _FakeToggleFavorite(toggle ?? const Ok<bool>(false)),
    setStatus ?? _FakeSetStatus(),
  );
}

void main() {
  test('estante sem livros vira estado vazio', () async {
    final FavoritesController controller = _build();

    await controller.load();

    expect(controller.state, isA<EmptyState<List<ShelfEntry>>>());
    controller.dispose();
  });

  test('remover tira o livro da lista e chama o caso de uso', () async {
    final _FakeToggleFavorite toggle = _FakeToggleFavorite(const Ok<bool>(false));
    final FavoritesController controller = FavoritesController(
      _FakeGetFavorites(const Ok<List<ShelfEntry>>(<ShelfEntry>[_duneEntry, _hobbitEntry])),
      toggle,
      _FakeSetStatus(),
    );

    await controller.load();
    final String message = await controller.remove(_dune);

    expect(controller.state.dataOrNull, <ShelfEntry>[_hobbitEntry]);
    expect(toggle.calls.single.id, _dune.id);
    expect(message, contains('Duna'));

    controller.dispose();
  });

  test('falha ao remover devolve o livro para a lista', () async {
    final FavoritesController controller = _build(
      shelf: const <ShelfEntry>[_duneEntry, _hobbitEntry],
      toggle: const Err<bool>(CacheFailure()),
    );

    await controller.load();
    final String message = await controller.remove(_dune);

    expect(controller.state.dataOrNull, <ShelfEntry>[_duneEntry, _hobbitEntry]);
    expect(message, const CacheFailure().message);

    controller.dispose();
  });

  group('prateleiras', () {
    test('o filtro recorta sem ir ao disco de novo', () async {
      final _FakeGetFavorites source = _FakeGetFavorites(
        const Ok<List<ShelfEntry>>(<ShelfEntry>[_duneEntry, _hobbitEntry]),
      );
      final FavoritesController controller =
          FavoritesController(source, _FakeToggleFavorite(const Ok<bool>(false)), _FakeSetStatus());

      await controller.load();
      expect(controller.visibleEntries, hasLength(2));

      controller.setFilter(ReadingStatus.read);

      expect(controller.visibleEntries, <ShelfEntry>[_hobbitEntry]);
      // O estado guarda a estante inteira: trocar de aba não recarrega nada.
      expect(controller.state.dataOrNull, hasLength(2));

      controller.setFilter(null);
      expect(controller.visibleEntries, hasLength(2));

      controller.dispose();
    });

    test('a contagem cobre toda prateleira, inclusive as vazias', () async {
      final FavoritesController controller =
          _build(shelf: const <ShelfEntry>[_duneEntry, _hobbitEntry]);

      await controller.load();

      expect(controller.counts[ReadingStatus.wantToRead], 1);
      expect(controller.counts[ReadingStatus.read], 1);
      // Prateleira sem livro precisa aparecer como zero, não como ausente:
      // a aba mostra o número.
      expect(controller.counts[ReadingStatus.reading], 0);
      expect(controller.total, 2);

      controller.dispose();
    });

    test('mudar de prateleira é otimista e persiste', () async {
      final _FakeSetStatus setStatus = _FakeSetStatus();
      final FavoritesController controller =
          _build(shelf: const <ShelfEntry>[_duneEntry], setStatus: setStatus);

      await controller.load();
      final String message =
          await controller.changeStatus(_duneEntry, ReadingStatus.reading);

      expect(controller.state.dataOrNull!.single.status, ReadingStatus.reading);
      expect(setStatus.calls.single.status, ReadingStatus.reading);
      expect(setStatus.calls.single.book.id, _dune.id);
      expect(message, contains('Lendo'));

      controller.dispose();
    });

    test('falha ao mudar de prateleira desfaz a marcação na tela', () async {
      final FavoritesController controller = _build(
        shelf: const <ShelfEntry>[_duneEntry],
        setStatus: _FakeSetStatus(const CacheFailure()),
      );

      await controller.load();
      final String message =
          await controller.changeStatus(_duneEntry, ReadingStatus.read);

      expect(controller.state.dataOrNull!.single.status, ReadingStatus.wantToRead);
      expect(message, const CacheFailure().message);

      controller.dispose();
    });

    test('remarcar para a prateleira atual não escreve nada', () async {
      final _FakeSetStatus setStatus = _FakeSetStatus();
      final FavoritesController controller =
          _build(shelf: const <ShelfEntry>[_duneEntry], setStatus: setStatus);

      await controller.load();
      final String message =
          await controller.changeStatus(_duneEntry, ReadingStatus.wantToRead);

      expect(setStatus.calls, isEmpty);
      expect(message, isEmpty);

      controller.dispose();
    });
  });
}
