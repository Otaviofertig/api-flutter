import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail.dart';
import 'book_model.dart';

/// DTO de [BookDetail] para `GET /works/{id}.json`.
///
/// O endpoint de *work* não devolve nomes de autores (apenas referências
/// `/authors/OLxxxA`) nem `cover_i`; por isso aceitamos um [fallback] vindo da
/// busca para completar esses campos sem uma requisição extra.
final class BookDetailModel extends BookDetail {
  const BookDetailModel({
    required super.book,
    super.description,
    super.subjects,
    super.coverIds,
  });

  factory BookDetailModel.fromJson(Map<String, dynamic> json, {Book? fallback}) {
    final String id = ApiConstants.normalizeWorkId(
      _string(json['key']) ?? fallback?.id ?? '',
    );
    final List<int> covers = _intList(json['covers']).where((int c) => c > 0).toList(growable: false);

    final Book book = Book(
      id: id,
      title: _string(json['title']) ?? fallback?.title ?? 'Título não informado',
      authors: fallback?.authors ?? const <String>[],
      firstPublishYear: _year(json['first_publish_date']) ?? fallback?.firstPublishYear,
      coverId: covers.isNotEmpty ? covers.first : fallback?.coverId,
      editionCount: fallback?.editionCount ?? 0,
    );

    return BookDetailModel(
      book: book,
      description: _description(json['description']),
      subjects: _stringList(json['subjects']),
      coverIds: covers,
    );
  }

  BookModel get bookModel => BookModel.fromEntity(book);

  // --- Coerção defensiva -----------------------------------------------------

  /// `description` vem ora como String, ora como `{type, value}`.
  static String? _description(Object? value) {
    if (value is String) return _string(value);
    if (value is Map && value['value'] is String) return _string(value['value']);
    return null;
  }

  /// `first_publish_date` pode ser "1937", "October 1937" ou "1 Sep 1937".
  static int? _year(Object? value) {
    final String? raw = _string(value);
    if (raw == null) return null;
    final RegExpMatch? match = RegExp(r'\b(\d{4})\b').firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value.map(_string).whereType<String>().toList(growable: false);
  }

  static List<int> _intList(Object? value) {
    if (value is! List) return const <int>[];
    return value
        .map((Object? e) => e is num ? e.toInt() : int.tryParse('$e'))
        .whereType<int>()
        .toList(growable: false);
  }
}
