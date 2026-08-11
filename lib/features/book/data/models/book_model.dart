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
      firstPublishYear: _int(json['first_publish_year']),
      coverId: _int(json['cover_i']),
      editionCount: _int(json['edition_count']) ?? 0,
    );
  }

  /// Reidrata um livro salvo na estante local.
  factory BookModel.fromLocalJson(Map<String, dynamic> json) {
    return BookModel(
      id: _string(json['id']) ?? '',
      title: _string(json['title']) ?? 'Título não informado',
      authors: _stringList(json['authors']),
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
        'firstPublishYear': firstPublishYear,
        'coverId': coverId,
        'editionCount': editionCount,
      };

  Book toEntity() => Book(
        id: id,
        title: title,
        authors: authors,
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

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map(_string)
        .whereType<String>()
        .toList(growable: false);
  }
}
