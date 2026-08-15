import 'package:flutter_test/flutter_test.dart';
import 'package:libria/core/error/failures.dart';
import 'package:libria/core/error/result.dart';
import 'package:libria/features/book/domain/entities/book.dart';
import 'package:libria/features/book/domain/entities/reading_status.dart';
import 'package:libria/features/book/domain/entities/shelf_entry.dart';
import 'package:libria/features/book/domain/repositories/book_repository.dart';
import 'package:libria/features/book/domain/usecases/set_reading_status.dart';

/// Estante em memória, registrando por qual caminho cada escrita veio.
class _FakeShelf implements IFavoriteRepository {
  final Map<String, ReadingStatus> shelf = <String, ReadingStatus>{};
  final List<String> added = <String>[];
  final List<String> restatused = <String>[];

  Failure? failOnWrite;

  @override
  Future<Result<bool>> isFavorite(String bookId) async =>
      Ok<bool>(shelf.containsKey(bookId));

  @override
  Future<Result<void>> addFavorite(
    Book book, {
    ReadingStatus status = ReadingStatus.initial,
  }) async {
    final Failure? error = failOnWrite;
    if (error != null) return Err<void>(error);

    added.add(book.id);
    shelf[book.id] = status;
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> setStatus({
    required String bookId,
    required ReadingStatus status,
  }) async {
    final Failure? error = failOnWrite;
    if (error != null) return Err<void>(error);

    restatused.add(bookId);
    shelf[bookId] = status;
    return const Ok<void>(null);
  }

  @override
  Future<Result<ReadingStatus?>> statusOf(String bookId) async =>
      Ok<ReadingStatus?>(shelf[bookId]);

  @override
  Future<Result<List<ShelfEntry>>> getFavorites() async =>
      const Ok<List<ShelfEntry>>(<ShelfEntry>[]);

  @override
  Future<Result<void>> removeFavorite(String bookId) async {
    shelf.remove(bookId);
    return const Ok<void>(null);
  }
}

const Book _dune = Book(id: 'OL1W', title: 'Duna');

void main() {
  group('SetReadingStatus', () {
    test('livro fora da estante entra já marcado', () async {
      // Marcar "Lendo" num livro recém-encontrado é um jeito legítimo de
      // salvá-lo: exigir "adicionar" antes seria burocracia.
      final _FakeShelf shelf = _FakeShelf();
      final SetReadingStatus usecase = SetReadingStatus(shelf);

      final Result<ReadingStatus> result = await usecase(
        const SetReadingStatusParams(book: _dune, status: ReadingStatus.reading),
      );

      expect(result.valueOrNull, ReadingStatus.reading);
      expect(shelf.added, <String>['OL1W']);
      expect(shelf.restatused, isEmpty);
      expect(shelf.shelf['OL1W'], ReadingStatus.reading);
    });

    test('livro já na estante só muda de prateleira', () async {
      final _FakeShelf shelf = _FakeShelf();
      shelf.shelf['OL1W'] = ReadingStatus.wantToRead;
      final SetReadingStatus usecase = SetReadingStatus(shelf);

      final Result<ReadingStatus> result = await usecase(
        const SetReadingStatusParams(book: _dune, status: ReadingStatus.read),
      );

      expect(result.valueOrNull, ReadingStatus.read);
      // Não passa por addFavorite: isso reiniciaria o registro.
      expect(shelf.added, isEmpty);
      expect(shelf.restatused, <String>['OL1W']);
    });

    test('falha na escrita não vira sucesso silencioso', () async {
      final _FakeShelf shelf = _FakeShelf()..failOnWrite = const CacheFailure();
      final SetReadingStatus usecase = SetReadingStatus(shelf);

      final Result<ReadingStatus> result = await usecase(
        const SetReadingStatusParams(book: _dune, status: ReadingStatus.read),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<CacheFailure>());
      expect(shelf.shelf, isEmpty);
    });
  });

  group('ReadingStatus', () {
    test('a chave persistida é estável e não é o nome do valor', () {
      // Renomear o valor no código não pode invalidar estante gravada.
      expect(ReadingStatus.wantToRead.storageKey, 'quero_ler');
      expect(ReadingStatus.reading.storageKey, 'lendo');
      expect(ReadingStatus.read.storageKey, 'lido');
    });

    test('round-trip pela chave preserva o valor', () {
      for (final ReadingStatus status in ReadingStatus.values) {
        expect(ReadingStatus.fromStorage(status.storageKey), status);
      }
    });

    test('lixo no disco cai no estado inicial', () {
      expect(ReadingStatus.fromStorage(null), ReadingStatus.initial);
      expect(ReadingStatus.fromStorage(42), ReadingStatus.initial);
      expect(ReadingStatus.fromStorage('wantToRead'), ReadingStatus.initial);
    });
  });
}
