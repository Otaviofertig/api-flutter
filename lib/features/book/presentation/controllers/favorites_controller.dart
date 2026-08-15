import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../../../core/state/ui_state.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/set_reading_status.dart';
import '../../domain/usecases/toggle_favorite.dart';

/// Controller da "Minha Estante".
///
/// O estado guarda a estante inteira; o filtro por status é derivado na
/// leitura. Assim trocar de aba não vai ao disco, e a contagem de cada
/// prateleira sai da mesma lista que já está em memória.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this._getFavorites, this._toggleFavorite, this._setStatus);

  final GetFavorites _getFavorites;
  final ToggleFavorite _toggleFavorite;
  final SetReadingStatus _setStatus;

  UiState<List<ShelfEntry>> _state = const UiState<List<ShelfEntry>>.idle();
  UiState<List<ShelfEntry>> get state => _state;

  /// `null` = todas as prateleiras.
  ReadingStatus? _filter;
  ReadingStatus? get filter => _filter;

  bool _disposed = false;

  /// Entradas visíveis com o filtro atual.
  List<ShelfEntry> get visibleEntries {
    final List<ShelfEntry> all = _state.dataOrNull ?? const <ShelfEntry>[];
    final ReadingStatus? status = _filter;

    if (status == null) return all;
    return all.where((ShelfEntry e) => e.status == status).toList(growable: false);
  }

  /// Quantos livros há em cada prateleira. Alimenta os contadores das abas.
  Map<ReadingStatus, int> get counts {
    final Map<ReadingStatus, int> tally = <ReadingStatus, int>{
      for (final ReadingStatus status in ReadingStatus.values) status: 0,
    };

    for (final ShelfEntry entry in _state.dataOrNull ?? const <ShelfEntry>[]) {
      tally[entry.status] = (tally[entry.status] ?? 0) + 1;
    }
    return tally;
  }

  int get total => _state.dataOrNull?.length ?? 0;

  void setFilter(ReadingStatus? status) {
    if (status == _filter) return;
    _filter = status;
    _notify();
  }

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _emit(const UiState<List<ShelfEntry>>.loading());

    final Result<List<ShelfEntry>> result = await _getFavorites();

    _emit(
      result.fold(
        UiState<List<ShelfEntry>>.error,
        (List<ShelfEntry> shelf) => shelf.isEmpty
            ? const UiState<List<ShelfEntry>>.empty(
                'Sua estante está vazia. Busque um livro e toque em '
                '"Adicionar à Minha Estante".',
              )
            : UiState<List<ShelfEntry>>.success(shelf),
      ),
    );
  }

  /// Remove da estante com atualização otimista: a UI responde na hora e,
  /// se a persistência falhar, o item volta para a lista.
  Future<String> remove(Book book) async {
    final List<ShelfEntry>? current = _state.dataOrNull;
    if (current == null) return '';

    final List<ShelfEntry> without =
        current.where((ShelfEntry e) => e.id != book.id).toList(growable: false);
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

  /// Move o livro de prateleira, também de forma otimista.
  ///
  /// Trocar de status pode tirar o livro da aba visível no mesmo instante —
  /// por isso o feedback diz para onde ele foi, e não só que deu certo.
  Future<String> changeStatus(ShelfEntry entry, ReadingStatus status) async {
    final List<ShelfEntry>? current = _state.dataOrNull;
    if (current == null || entry.status == status) return '';

    final List<ShelfEntry> updated = current
        .map((ShelfEntry e) => e.id == entry.id ? e.withStatus(status) : e)
        .toList(growable: false);
    _emit(_stateForList(updated));

    final Result<ReadingStatus> result =
        await _setStatus(SetReadingStatusParams(book: entry.book, status: status));

    return result.fold(
      (failure) {
        _emit(_stateForList(current)); // desfaz
        return failure.message;
      },
      (ReadingStatus applied) => '"${entry.book.title}" agora está em "${applied.label}".',
    );
  }

  UiState<List<ShelfEntry>> _stateForList(List<ShelfEntry> shelf) {
    return shelf.isEmpty
        ? const UiState<List<ShelfEntry>>.empty('Sua estante está vazia de novo.')
        : UiState<List<ShelfEntry>>.success(shelf);
  }

  void _emit(UiState<List<ShelfEntry>> state) {
    _state = state;
    if (_disposed) return;
    notifyListeners();
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
