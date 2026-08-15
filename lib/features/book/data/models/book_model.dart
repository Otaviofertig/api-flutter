import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/book.dart';

/// DTO de [Book]: converte JSON da Open Library ⇄ entidade de domínio.
///
/// Toda a tolerância a campos ausentes/tipos inesperados fica aqui — a
/// entidade permanece limpa.
final class BookModel extends Book {
  const BookModel({
    required super.id,
    required super.title,
    super.authors,
    super.authorIds,
    super.firstPublishYear,
    super.coverId,
    super.editionCount,
  });

  /// Item de `GET /search.json` → `docs[]`.
  factory BookModel.fromSearchJson(Map<String, dynamic> json) {
    return BookModel(
      id: ApiConstants.normalizeWorkId(_string(json['key']) ?? ''),
      title: _string(json['title']) ?? 'Título não informado',
      authors: _stringList(json['author_name']),
      authorIds: _authorIds(json['author_key']),
      firstPublishYear: _int(json['first_publish_year']),
      coverId: _int(json['cover_i']),
      editionCount: _int(json['edition_count']) ?? 0,
    );
  }

  /// Item de `GET /authors/{id}/works.json` → `entries[]`.
  ///
  /// O registro da *work* não traz nome de autor, ano nem contagem de edições
  /// — só a obra em si. O nome vem de quem já está na tela (a ficha do autor),
  /// o que evita uma requisição por livro só para escrever o mesmo nome.
  factory BookModel.fromAuthorWorkJson(
    Map<String, dynamic> json, {
    required String authorId,
    required String authorName,
  }) {
    final List<int> covers = _intList(json['covers']);

    return BookModel(
      id: ApiConstants.normalizeWorkId(_string(json['key']) ?? ''),
      title: _string(json['title']) ?? 'Título não informado',
      authors: <String>[authorName],
      authorIds: <String>[authorId],
      firstPublishYear: _yearFrom(json['first_publish_date']),
      coverId: covers.isEmpty ? null : covers.first,
    );
  }

  /// Reidrata um livro salvo na estante local.
  ///
  /// `authorIds` é posterior ao primeiro formato gravado: estante antiga
  /// simplesmente não tem a chave e volta com a lista vazia, o que só custa o
  /// link para a ficha do autor.
  factory BookModel.fromLocalJson(Map<String, dynamic> json) {
    return BookModel(
      id: _string(json['id']) ?? '',
      title: _string(json['title']) ?? 'Título não informado',
      authors: _stringList(json['authors']),
      authorIds: _stringList(json['authorIds']),
      firstPublishYear: _int(json['firstPublishYear']),
      coverId: _int(json['coverId']),
      editionCount: _int(json['editionCount']) ?? 0,
    );
  }

  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      authors: book.authors,
      authorIds: book.authorIds,
      firstPublishYear: book.firstPublishYear,
      coverId: book.coverId,
      editionCount: book.editionCount,
    );
  }

  /// Formato persistido localmente (shared_preferences).
  Map<String, dynamic> toLocalJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'authors': authors,
        'authorIds': authorIds,
        'firstPublishYear': firstPublishYear,
        'coverId': coverId,
        'editionCount': editionCount,
      };

  Book toEntity() => Book(
        id: id,
        title: title,
        authors: authors,
        authorIds: authorIds,
        firstPublishYear: firstPublishYear,
        coverId: coverId,
        editionCount: editionCount,
      );

  // --- Coerção defensiva -----------------------------------------------------

  static String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// `author_key` vem como `["OL26320A"]`, mas normaliza-se por garantia:
  /// outros endpoints devolvem a mesma referência como `/authors/OL26320A`.
  static List<String> _authorIds(Object? value) {
    return _stringList(value)
        .map(ApiConstants.normalizeAuthorId)
        .where((String id) => id.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map(_string)
        .whereType<String>()
        .toList(growable: false);
  }

  /// Só capas válidas: a Open Library usa `-1` para "sem capa".
  static List<int> _intList(Object? value) {
    if (value is! List) return const <int>[];
    return value.map(_int).whereType<int>().where((int id) => id > 0).toList(growable: false);
  }

  /// `first_publish_date` vem em texto livre: "1937", "October 1937", "1 Sep 1937".
  static int? _yearFrom(Object? value) {
    final String? raw = _string(value);
    if (raw == null) return null;

    final RegExpMatch? match = RegExp(r'\b(\d{4})\b').firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
