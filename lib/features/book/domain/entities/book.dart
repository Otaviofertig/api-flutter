/// Um livro como aparece na listagem de busca / na estante.
///
/// Entidade pura: sem `fromJson`, sem Flutter, sem conhecimento de HTTP.
/// A montagem de URL de capa é responsabilidade da camada de apresentação
/// (a partir de [coverId]), mantendo o domínio livre de detalhes de infra.
class Book {
  const Book({
    required this.id,
    required this.title,
    this.authors = const <String>[],
    this.firstPublishYear,
    this.coverId,
    this.editionCount = 0,
  });

  /// Identificador da *work* na Open Library (ex.: `OL45804W`), sem o prefixo.
  final String id;
  final String title;
  final List<String> authors;
  final int? firstPublishYear;
  final int? coverId;
  final int editionCount;

  bool get hasCover => coverId != null && coverId! > 0;

  /// Autores formatados para exibição, com fallback explícito.
  String get authorsLabel => authors.isEmpty ? 'Autor desconhecido' : authors.join(', ');

  String get yearLabel => firstPublishYear?.toString() ?? '—';

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Book && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Book($id, $title)';
}
