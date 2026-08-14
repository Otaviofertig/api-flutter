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
    this.authorIds = const <String>[],
    this.firstPublishYear,
    this.coverId,
    this.editionCount = 0,
  });

  /// Identificador da *work* na Open Library (ex.: `OL45804W`), sem o prefixo.
  final String id;
  final String title;
  final List<String> authors;

  /// Ids dos autores (ex.: `OL26320A`), paralelos a [authors] quando a API
  /// devolve os dois. É o que permite abrir a ficha do autor.
  final List<String> authorIds;

  final int? firstPublishYear;
  final int? coverId;
  final int editionCount;

  bool get hasCover => coverId != null && coverId! > 0;

  /// Autores formatados para exibição, com fallback explícito.
  String get authorsLabel => authors.isEmpty ? 'Autor desconhecido' : authors.join(', ');

  /// Autores pareados com seus ids, para a UI decidir quais viram link.
  ///
  /// As duas listas chegam paralelas da busca, mas nada garante o mesmo
  /// tamanho: obra com autor sem registro próprio devolve nome sem chave.
  /// Índice sem id correspondente vira `null` em vez de desalinhar o par.
  List<({String name, String? id})> get authorEntries {
    return <({String name, String? id})>[
      for (int i = 0; i < authors.length; i++)
        (name: authors[i], id: i < authorIds.length ? authorIds[i] : null),
    ];
  }

  String get yearLabel => firstPublishYear?.toString() ?? '—';

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Book && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Book($id, $title)';
}
