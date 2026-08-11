import 'package:libria/features/book/data/models/book_detail_model.dart';
import 'package:libria/features/book/data/models/book_model.dart';
import 'package:libria/features/book/domain/entities/book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookModel.fromSearchJson', () {
    test('mapeia um doc completo da busca', () {
      final BookModel book = BookModel.fromSearchJson(<String, dynamic>{
        'key': '/works/OL45804W',
        'title': 'Fantastic Mr Fox',
        'author_name': <String>['Roald Dahl'],
        'first_publish_year': 1970,
        'cover_i': 6498519,
        'edition_count': 63,
      });

      expect(book.id, 'OL45804W');
      expect(book.title, 'Fantastic Mr Fox');
      expect(book.authors, <String>['Roald Dahl']);
      expect(book.firstPublishYear, 1970);
      expect(book.hasCover, isTrue);
      expect(book.editionCount, 63);
    });

    test('tolera campos ausentes ou com tipo inesperado', () {
      final BookModel book = BookModel.fromSearchJson(<String, dynamic>{
        'key': '/works/OL1W',
        'author_name': <dynamic>[null, '', 'Autor Válido'],
        'first_publish_year': '1999',
        'cover_i': null,
      });

      expect(book.title, 'Título não informado');
      expect(book.authors, <String>['Autor Válido']);
      expect(book.firstPublishYear, 1999);
      expect(book.hasCover, isFalse);
      expect(book.authorsLabel, 'Autor Válido');
    });

    test('round-trip de persistência local preserva os dados', () {
      const Book original = Book(
        id: 'OL2W',
        title: 'Dom Casmurro',
        authors: <String>['Machado de Assis'],
        firstPublishYear: 1899,
        coverId: 123,
        editionCount: 7,
      );

      final BookModel restored = BookModel.fromLocalJson(
        BookModel.fromEntity(original).toLocalJson(),
      );

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.authors, original.authors);
      expect(restored.firstPublishYear, original.firstPublishYear);
      expect(restored.coverId, original.coverId);
      expect(restored.editionCount, original.editionCount);
    });
  });

  group('BookDetailModel.fromJson', () {
    test('lê description em formato objeto e extrai o ano da data', () {
      final BookDetailModel detail = BookDetailModel.fromJson(
        <String, dynamic>{
          'key': '/works/OL45804W',
          'title': 'The Hobbit',
          'description': <String, dynamic>{'type': '/type/text', 'value': 'Uma jornada.'},
          'subjects': <String>['Fantasy', 'Adventure'],
          'covers': <int>[-1, 8231856],
          'first_publish_date': 'October 1937',
        },
        fallback: const Book(id: 'OL45804W', title: 'The Hobbit', authors: <String>['Tolkien']),
      );

      expect(detail.id, 'OL45804W');
      expect(detail.description, 'Uma jornada.');
      expect(detail.subjects, <String>['Fantasy', 'Adventure']);
      expect(detail.firstPublishYear, 1937);
      // O -1 é descartado; a capa preferida é a primeira válida.
      expect(detail.preferredCoverId, 8231856);
      // Autores não vêm no endpoint de work: herdados do fallback da busca.
      expect(detail.authors, <String>['Tolkien']);
    });

    test('description em String simples e ausência de capas usa o fallback', () {
      final BookDetailModel detail = BookDetailModel.fromJson(
        <String, dynamic>{'key': '/works/OL3W', 'title': 'Sem capa', 'description': 'Resumo'},
        fallback: const Book(id: 'OL3W', title: 'Sem capa', coverId: 999, firstPublishYear: 2001),
      );

      expect(detail.hasDescription, isTrue);
      expect(detail.preferredCoverId, 999);
      expect(detail.firstPublishYear, 2001);
      expect(detail.subjects, isEmpty);
    });
  });
}
