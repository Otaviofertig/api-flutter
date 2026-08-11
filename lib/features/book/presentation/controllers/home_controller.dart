import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/result.dart';
import '../../../../core/state/ui_state.dart';
import '../../../../core/utils/debouncer.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/search_books.dart';

/// Controller da Home: busca com debounce, paginação e estados de tela.
///
/// Não conhece Flutter Material nem HTTP — só o caso de uso [SearchBooks].
class HomeController extends ChangeNotifier {
  HomeController(this._searchBooks, {Debouncer? debouncer, int? pageSize})
      : _debouncer = debouncer ?? Debouncer(),
        _pageSize = pageSize ?? AppConfig.instance.searchPageSize;

  final SearchBooks _searchBooks;
  final Debouncer _debouncer;

  /// Espelha o `limit` enviado à API: uma página cheia sugere que há mais.
  final int _pageSize;

  UiState<List<Book>> _state = const UiState<List<Book>>.idle();
  UiState<List<Book>> get state => _state;

  String _query = '';
  String get query => _query;

  int _page = 1;
  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _loadingMore = false;
  bool get isLoadingMore => _loadingMore;

  /// Cada busca recebe um id; respostas de buscas antigas são descartadas.
  /// Sem isso, uma requisição lenta poderia sobrescrever um resultado novo.
  int _requestId = 0;

  bool _disposed = false;

  /// Chamado a cada tecla digitada: agenda a busca e cancela a anterior.
  void onQueryChanged(String value) {
    _query = value;

    if (value.trim().isEmpty) {
      _debouncer.cancel();
      _resetToIdle();
      return;
    }

    _debouncer.run(search);
  }

  /// Dispara a busca imediatamente (ex.: ação "buscar" do teclado).
  Future<void> searchNow(String value) {
    _query = value;
    _debouncer.cancel();
    return search();
  }

  Future<void> search() async {
    final String term = _query.trim();
    if (term.isEmpty) {
      _resetToIdle();
      return;
    }

    final int requestId = ++_requestId;
    _page = 1;
    _hasMore = false;
    _emit(const UiState<List<Book>>.loading());

    final Result<List<Book>> result =
        await _searchBooks(SearchBooksParams(query: term, page: _page));

    if (requestId != _requestId) return; // resposta obsoleta

    _emit(
      result.fold(
        UiState<List<Book>>.error,
        (List<Book> books) {
          _hasMore = books.length >= _pageSize;
          return books.isEmpty
              ? UiState<List<Book>>.empty('Nenhum livro encontrado para "$term".')
              : UiState<List<Book>>.success(books);
        },
      ),
    );
  }

  /// Carrega a próxima página e concatena ao resultado atual.
  Future<void> loadMore() async {
    final List<Book>? current = _state.dataOrNull;
    if (_loadingMore || !_hasMore || current == null) return;

    _loadingMore = true;
    _notify();

    final int requestId = _requestId;
    final Result<List<Book>> result =
        await _searchBooks(SearchBooksParams(query: _query.trim(), page: _page + 1));

    if (requestId != _requestId) return; // a busca mudou no meio do caminho

    _loadingMore = false;

    result.fold(
      (_) {
        // Falha ao paginar não descarta o que já está na tela: apenas
        // encerra a paginação silenciosamente.
        _hasMore = false;
      },
      (List<Book> books) {
        _page += 1;
        _hasMore = books.length >= _pageSize;

        // A Open Library repete obras entre páginas em algumas consultas.
        final Set<String> seen = current.map((Book b) => b.id).toSet();
        final List<Book> novos =
            books.where((Book b) => seen.add(b.id)).toList(growable: false);

        _state = UiState<List<Book>>.success(<Book>[...current, ...novos]);
      },
    );

    _notify();
  }

  void clear() {
    _debouncer.cancel();
    _query = '';
    _requestId++;
    _resetToIdle();
  }

  void _resetToIdle() {
    _page = 1;
    _hasMore = false;
    _loadingMore = false;
    _emit(const UiState<List<Book>>.idle());
  }

  void _emit(UiState<List<Book>> state) {
    _state = state;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debouncer.dispose();
    super.dispose();
  }
}
