import 'book.dart';
import 'reading_status.dart';

/// Um livro na estante, junto do ponto de leitura em que ele está.
///
/// Composição em vez de um campo `status` dentro de [Book]: o mesmo livro
/// vindo da busca não tem status nenhum, e carregar um campo que só faz
/// sentido na estante sujaria a entidade em toda tela que a usa.
class ShelfEntry {
  const ShelfEntry({required this.book, this.status = ReadingStatus.initial});

  final Book book;
  final ReadingStatus status;

  String get id => book.id;

  ShelfEntry withStatus(ReadingStatus status) =>
      ShelfEntry(book: book, status: status);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShelfEntry && other.id == id && other.status == status);

  @override
  int get hashCode => Object.hash(id, status);

  @override
  String toString() => 'ShelfEntry($id, ${status.storageKey})';
}
