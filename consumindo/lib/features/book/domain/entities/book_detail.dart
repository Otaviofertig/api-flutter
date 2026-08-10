import 'book.dart';

/// Detalhes completos de uma obra (endpoint `/works/{id}.json`).
///
/// Composição em vez de herança: um detalhe *tem* um [Book] resumido, o que
/// evita que [Book] precise carregar campos opcionais de detalhe (LSP/ISP).
class BookDetail {
  const BookDetail({
    required this.book,
    this.description,
    this.subjects = const <String>[],
    this.coverIds = const <int>[],
  });

  final Book book;
  final String? description;
  final List<String> subjects;

  /// Todas as capas conhecidas da obra; a primeira válida é a preferida.
  final List<int> coverIds;

  String get id => book.id;
  String get title => book.title;
  List<String> get authors => book.authors;
  int? get firstPublishYear => book.firstPublishYear;

  bool get hasDescription => (description?.trim().isNotEmpty ?? false);

  /// Capa em melhor resolução disponível: a do detalhe ou, na falta, a da busca.
  int? get preferredCoverId {
    for (final int id in coverIds) {
      if (id > 0) return id;
    }
    return book.coverId;
  }

  /// Assuntos limitados para não estourar o layout de chips.
  List<String> topSubjects([int max = 12]) =>
      subjects.length <= max ? subjects : subjects.sublist(0, max);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BookDetail && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
