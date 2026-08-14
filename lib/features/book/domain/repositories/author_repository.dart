import '../../../../core/error/result.dart';
import '../entities/author.dart';
import '../entities/book.dart';

/// Contrato de acesso a autores (Open Library).
///
/// Interface separada de `IBookRepository` pelo mesmo princípio que já separa
/// estante de rede (ISP): a tela de busca não precisa depender de autores.
abstract interface class IAuthorRepository {
  /// Ficha do autor. [authorId] aceita `OL26320A` ou `/authors/OL26320A`.
  Future<Result<Author>> getAuthor(String authorId);

  /// Obras do autor. [page] começa em 1 e vira `offset` na chamada.
  ///
  /// [authorName] entra nos livros devolvidos: o endpoint de obras não repete
  /// o nome em cada registro, e quem já está na ficha do autor sabe qual é.
  /// Mesmo arranjo do `fallback` em `getBookDetail` — completar o que a API
  /// omite sem cobrar uma requisição por item.
  Future<Result<List<Book>>> getAuthorWorks({
    required String authorId,
    required String authorName,
    int page,
    int? limit,
  });
}
