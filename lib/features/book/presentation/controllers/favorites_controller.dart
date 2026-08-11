import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/state/ui_state.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/toggle_favorite.dart';

/// Controller da "Minha Estante".
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._getFavorites, this._toggleFavorite);

  final GetFavorites _getFavorites;
  final ToggleFavorite _toggleFavorite;

  UiState<List<Book>> _state = const UiState<List<Book>>.idle();
  UiState<List<Book>> get state => _state;

  bool _disposed = false;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _emit(const UiState<List<Book>>.loading());

    final Result<List<Book>> result = await _getFavorites();

    _emit(
      result.fold(
        UiState<List<Book>>.error,
        (List<Book> books) => books.isEmpty
            ? const UiState<List<Book>>.empty(
                'Sua estante está vazia. Busque um livro e toque em '
                '"Adicionar à Minha Estante".',
              )
            : UiState<List<Book>>.success(books),
      ),
    );
  }

  /// Remove da estante com atualização otimista: a UI responde na hora e,
  /// se a persistência falhar, o item volta para a lista.
  Future<String> remove(Book book) async {
    final List<Book>? current = _state.dataOrNull;
    if (current == null) return '';

    final List<Book> without =
        current.where((Book b) => b.id != book.id).toList(growable: false);
    _emit(_stateForList(without));

    final Result<bool> result = await _toggleFavorite(book);

    return result.fold(
      (failure) {
        _emit(_stateForList(current)); // desfaz
        return failure.message;
      },
      (_) => '"${book.title}" saiu da sua estante.',
    );
  }

  UiState<List<Book>> _stateForList(List<Book> books) {
    return books.isEmpty
        ? const UiState<List<Book>>.empty('Sua estante está vazia de novo.')
        : UiState<List<Book>>.success(books);
  }

  void _emit(UiState<List<Book>> state) {
    _state = state;
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
