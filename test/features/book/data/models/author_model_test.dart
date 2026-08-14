import 'package:flutter_test/flutter_test.dart';
import 'package:libria/features/book/data/models/author_model.dart';
import 'package:libria/features/book/data/models/book_model.dart';

void main() {
  group('AuthorModel.fromJson', () {
    test('lê o registro completo e normaliza a chave', () {
      final AuthorModel author = AuthorModel.fromJson(<String, dynamic>{
        'key': '/authors/OL23919A',
        'name': 'J. K. Rowling',
        'birth_date': '31 July 1965',
        'bio': <String, dynamic>{'type': '/type/text', 'value': 'Escritora britânica.'},
        'photos': <dynamic>[5543033, -1],
        'alternate_names': <dynamic>['Joanne Rowling', 'Robert Galbraith'],
      });

      expect(author.id, 'OL23919A');
      expect(author.name, 'J. K. Rowling');
      expect(author.bio, 'Escritora britânica.');
      expect(author.photoId, 5543033);
      expect(author.alternateNames, hasLength(2));
      expect(author.lifespanLabel, 'Nascimento: 31 July 1965');
    });

    test('bio em String simples também é aceita', () {
      final AuthorModel author = AuthorModel.fromJson(<String, dynamic>{
        'key': '/authors/OL1A',
        'name': 'Autor',
        'bio': 'Texto direto.',
      });

      expect(author.bio, 'Texto direto.');
      expect(author.hasBio, isTrue);
    });

    test('photos só com -1 significa sem retrato', () {
      // A Open Library devolve -1 em vez de omitir o campo.
      final AuthorModel author = AuthorModel.fromJson(<String, dynamic>{
        'key': '/authors/OL1A',
        'name': 'Autor',
        'photos': <dynamic>[-1],
      });

      expect(author.photoId, isNull);
      expect(author.hasPhoto, isFalse);
      expect(author.initials, 'A');
    });

    test('registro redirecionado cai no id que a tela pediu', () {
      final AuthorModel author = AuthorModel.fromJson(
        <String, dynamic>{'name': 'Autor'},
        fallbackId: 'OL999A',
      );

      expect(author.id, 'OL999A');
    });

    test('nome ausente não quebra a ficha', () {
      final AuthorModel author =
          AuthorModel.fromJson(<String, dynamic>{'key': '/authors/OL1A'});

      expect(author.name, 'Autor sem nome registrado');
      expect(author.initials, isNotEmpty);
      expect(author.lifespanLabel, isNull);
    });

    test('só data de morte rende rótulo próprio', () {
      final AuthorModel author = AuthorModel.fromJson(<String, dynamic>{
        'key': '/authors/OL1A',
        'name': 'Autor Antigo',
        'death_date': '1616',
      });

      expect(author.lifespanLabel, 'Falecimento: 1616');
    });

    test('nascimento e morte viram intervalo', () {
      final AuthorModel author = AuthorModel.fromJson(<String, dynamic>{
        'key': '/authors/OL1A',
        'name': 'J.R.R. Tolkien',
        'birth_date': '3 January 1892',
        'death_date': '2 September 1973',
      });

      expect(author.lifespanLabel, '3 January 1892 — 2 September 1973');
      expect(author.initials, 'JT');
    });
  });

  group('BookModel.fromAuthorWorkJson', () {
    test('completa o autor que o endpoint de obras não repete', () {
      final BookModel book = BookModel.fromAuthorWorkJson(
        <String, dynamic>{
          'key': '/works/OL45883W',
          'title': 'O Hobbit',
          'covers': <dynamic>[-1, 8231856],
          'first_publish_date': '21 September 1937',
        },
        authorId: 'OL26320A',
        authorName: 'J.R.R. Tolkien',
      );

      expect(book.id, 'OL45883W');
      expect(book.title, 'O Hobbit');
      expect(book.authors, <String>['J.R.R. Tolkien']);
      expect(book.authorIds, <String>['OL26320A']);
      // A primeira capa é -1 ("sem capa"): tem que cair na seguinte.
      expect(book.coverId, 8231856);
      expect(book.firstPublishYear, 1937);
    });

    test('obra sem capa, sem data e sem título ainda é utilizável', () {
      final BookModel book = BookModel.fromAuthorWorkJson(
        <String, dynamic>{'key': '/works/OL1W'},
        authorId: 'OL1A',
        authorName: 'Autor',
      );

      expect(book.id, 'OL1W');
      expect(book.title, 'Título não informado');
      expect(book.coverId, isNull);
      expect(book.firstPublishYear, isNull);
      expect(book.hasCover, isFalse);
    });
  });

  group('Book.authorEntries', () {
    test('pareia nomes com ids na mesma ordem', () {
      final BookModel book = BookModel.fromSearchJson(<String, dynamic>{
        'key': '/works/OL1W',
        'title': 'Obra',
        'author_name': <dynamic>['Autor Um', 'Autor Dois'],
        'author_key': <dynamic>['OL1A', 'OL2A'],
      });

      expect(book.authorEntries, <({String name, String? id})>[
        (name: 'Autor Um', id: 'OL1A'),
        (name: 'Autor Dois', id: 'OL2A'),
      ]);
    });

    test('nome sem id correspondente vira entrada sem link', () {
      // Acontece com autor que não tem registro próprio na Open Library:
      // desalinhar o par transformaria o link num destino errado.
      final BookModel book = BookModel.fromSearchJson(<String, dynamic>{
        'key': '/works/OL1W',
        'title': 'Obra',
        'author_name': <dynamic>['Autor Um', 'Autor Sem Registro'],
        'author_key': <dynamic>['OL1A'],
      });

      expect(book.authorEntries.last.id, isNull);
      expect(book.authorEntries.first.id, 'OL1A');
    });

    test('a estante antiga, sem authorIds gravado, só perde o link', () {
      final BookModel book = BookModel.fromLocalJson(<String, dynamic>{
        'id': 'OL1W',
        'title': 'Obra',
        'authors': <dynamic>['Autor Um'],
      });

      expect(book.authorIds, isEmpty);
      expect(book.authorEntries.single.name, 'Autor Um');
      expect(book.authorEntries.single.id, isNull);
    });

    test('o round-trip local preserva os ids', () {
      final BookModel original = BookModel.fromSearchJson(<String, dynamic>{
        'key': '/works/OL1W',
        'title': 'Obra',
        'author_name': <dynamic>['Autor Um'],
        'author_key': <dynamic>['OL1A'],
      });

      final BookModel restored = BookModel.fromLocalJson(original.toLocalJson());

      expect(restored.authorIds, <String>['OL1A']);
    });
  });
}
