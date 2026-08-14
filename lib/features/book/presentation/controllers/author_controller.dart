import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/result.dart';
import '../../../../core/state/ui_state.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/get_author.dart';
import '../../domain/usecases/get_author_works.dart';

/// Controller da ficha do autor: dados do autor e obras paginadas.
///
/// Os dois estados são separados porque falham separado: a bibliografia pode
/// cair sem levar junto o nome e a biografia que já estão na tela.
class AuthorController extends ChangeNotifier {
  AuthorController(
    this._getAuthor,
    this._getAuthorWorks, {
    required this.authorId,
    required this.authorName,
    int? pageSize,
  }) : _pageSize = pageSize ?? AppConfig.instance.searchPageSize;

  final GetAuthor _getAuthor;
  final GetAuthorWorks _getAuthorWorks;

  final String authorId;

  /// Nome que a tela anterior já conhecia. Serve de título enquanto a ficha
  /// carrega e alimenta as obras, que vêm sem nome de autor.
  final String authorName;

  final int _pageSize;

  UiState<Author> _author = const UiState<Author>.idle();
  UiState<Author> get author => _author;

  UiState<List<Book>> _works = const UiState<List<Book>>.idle();
  UiState<List<Book>> get works => _works;

  int _page = 1;
  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _loadingMore = false;
  bool get isLoadingMore => _loadingMore;

  bool _disposed = false;

  /// Nome a exibir: o da ficha quando ela chega, o herdado enquanto não chega.
  String get displayName => _author.dataOrNull?.name ?? authorName;

  /// Carrega ficha e primeira página de obras em paralelo.
  ///
  /// Em paralelo de propósito: são endpoints independentes, e encadear
  /// dobraria o tempo até a tela ficar pronta.
  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[loadAuthor(), loadWorks()]);
  }

  Future<void> loadAuthor() async {
    _author = const UiState<Author>.loading();
    _notify();

    final Result<Author> result = await _getAuthor(authorId);

    _author = result.fold(UiState<Author>.error, UiState<Author>.success);
    _notify();
  }

  Future<void> loadWorks() async {
    _page = 1;
    _hasMore = false;
    _works = const UiState<List<Book>>.loading();
    _notify();

    final Result<List<Book>> result = await _getAuthorWorks(
      AuthorWorksParams(
        authorId: authorId,
        authorName: authorName,
        page: _page,
        limit: _pageSize,
      ),
    );

    _works = result.fold(
      UiState<List<Book>>.error,
      (List<Book> books) {
        // Página cheia sugere que há mais — mesma heurística da busca.
        _hasMore = books.length >= _pageSize;
        return books.isEmpty
            ? const UiState<List<Book>>.empty(
                'A Open Library não lista obras para este autor.',
              )
            : UiState<List<Book>>.success(books);
      },
    );
    _notify();
  }

  /// Próxima página da bibliografia, concatenada ao que já está na tela.
  Future<void> loadMore() async {
    final List<Book>? current = _works.dataOrNull;
    if (_loadingMore || !_hasMore || current == null) return;

    _loadingMore = true;
    _notify();

    final Result<List<Book>> result = await _getAuthorWorks(
      AuthorWorksParams(
        authorId: authorId,
        authorName: authorName,
        page: _page + 1,
        limit: _pageSize,
      ),
    );

    _loadingMore = false;

    result.fold(
      (_) {
        // Falha ao paginar não descarta o que já está na tela: encerra a
        // paginação em silêncio, como na busca.
        _hasMore = false;
      },
      (List<Book> books) {
        _page += 1;
        _hasMore = books.length >= _pageSize;

        // O endpoint repete obras entre páginas quando o acervo muda no meio.
        final Set<String> seen = current.map((Book b) => b.id).toSet();
        final List<Book> fresh =
            books.where((Book b) => seen.add(b.id)).toList(growable: false);

        _works = UiState<List<Book>>.success(<Book>[...current, ...fresh]);
      },
    );

    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
