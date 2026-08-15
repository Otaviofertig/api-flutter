import '../../domain/entities/reading_status.dart';
import '../models/book_model.dart';
import '../models/shelf_entry_model.dart';

/// Fonte de dados local da estante. Lança `CacheException` em caso de erro.
abstract interface class IBookLocalDataSource {
  /// A estante inteira, cada livro com o seu status de leitura.
  Future<List<ShelfEntryModel>> getFavorites();

  /// Salva o livro. [status] só vale na primeira vez: livro que já está na
  /// estante não tem o status reescrito por um novo salvamento.
  Future<void> saveFavorite(BookModel book, {ReadingStatus status});

  Future<void> removeFavorite(String bookId);

  Future<bool> isFavorite(String bookId);

  /// Move o livro para outro ponto da leitura. Sem efeito se ele não estiver
  /// na estante.
  Future<void> setStatus(String bookId, ReadingStatus status);

  /// Status atual, ou `null` se o livro não está na estante.
  Future<ReadingStatus?> statusOf(String bookId);
}
