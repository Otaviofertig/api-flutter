import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/state/ui_state.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail.dart';
import '../../domain/usecases/get_book_detail.dart';
import '../../domain/usecases/is_favorite.dart';
import '../../domain/usecases/toggle_favorite.dart';

/// Controller (o "C" do MVC) da tela de detalhes.
///
/// Conhece apenas casos de uso — nunca repositórios, HTTP ou `shared_preferences`.
/// Expõe estado imutável e notifica a View via [ChangeNotifier].
class BookDetailController extends ChangeNotifier {
  /// Recebe apenas casos de uso — injeção por construtor, sem service locator
  /// aqui dentro (o `sl` fica na View, na fronteira do framework).
  ///
  /// [_initial] é o livro vindo da listagem: permite pintar título/autor/capa
  /// antes mesmo de a resposta do detalhe chegar.
  BookDetailController(
    this._getBookDetail,
    this._toggleFavorite,
    this._isFavorite,
    this._initial,
  );

  final GetBookDetail _getBookDetail;
  final ToggleFavorite _toggleFavorite;
  final IsFavorite _isFavorite;
  final Book _initial;

  Book get initial => _initial;

  UiState<BookDetail> _state = const UiState<BookDetail>.idle();
  UiState<BookDetail> get state => _state;

  bool _favorite = false;
  bool get isFavorite => _favorite;

  bool _favoriteBusy = false;
  bool get isFavoriteBusy => _favoriteBusy;

  bool _disposed = false;

  /// Carrega detalhe e status de favorito em paralelo.
  Future<void> load() async {
    _emit(const UiState<BookDetail>.loading());

    await Future.wait<void>(<Future<void>>[_loadDetail(), refreshFavoriteStatus()]);
  }

  Future<void> _loadDetail() async {
    final Result<BookDetail> result = await _getBookDetail(
      GetBookDetailParams(workId: _initial.id, fallback: _initial),
    );

    _emit(
      result.fold(
        UiState<BookDetail>.error,
        UiState<BookDetail>.success,
      ),
    );
  }

  Future<void> refreshFavoriteStatus() async {
    final Result<bool> result = await _isFavorite(_initial.id);
    final bool? value = result.valueOrNull;

    if (value != null && value != _favorite) {
      _favorite = value;
      _notify();
    }
  }

  /// Alterna o livro na estante e devolve a mensagem de feedback para a View.
  Future<String> toggleFavorite() async {
    if (_favoriteBusy) return '';

    _favoriteBusy = true;
    _notify();

    // Prefere os dados do detalhe (mais completos) para salvar na estante.
    final Book toSave = _state.dataOrNull?.book ?? _initial;
    final Result<bool> result = await _toggleFavorite(toSave);

    _favoriteBusy = false;

    final String message = result.fold(
      (failure) => failure.message,
      (bool isNowFavorite) {
        _favorite = isNowFavorite;
        return isNowFavorite
            ? 'Adicionado à Minha Estante.'
            : 'Removido da Minha Estante.';
      },
    );

    _notify();
    return message;
  }

  void _emit(UiState<BookDetail> state) {
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
    super.dispose();
  }
}
