import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/book_model.dart';
import 'book_local_datasource.dart';

/// Estante persistida em `shared_preferences` como uma lista de strings JSON.
///
/// Depende de [SharedPreferences] por injeção: trocar por Hive/Isar exige
/// apenas outra implementação de [IBookLocalDataSource].
final class BookLocalDataSourceImpl implements IBookLocalDataSource {
  const BookLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String favoritesKey = 'libria.favorites.v1';

  @override
  Future<List<BookModel>> getFavorites() async => _readAll();

  @override
  Future<void> saveFavorite(BookModel book) async {
    final List<BookModel> favorites = _readAll();
    if (favorites.any((BookModel b) => b.id == book.id)) return;

    // Mais recentes primeiro: a estante reflete a ordem de adição.
    await _writeAll(<BookModel>[book, ...favorites]);
  }

  @override
  Future<void> removeFavorite(String bookId) async {
    final List<BookModel> favorites = _readAll();
    final List<BookModel> updated =
        favorites.where((BookModel b) => b.id != bookId).toList(growable: false);

    if (updated.length == favorites.length) return;
    await _writeAll(updated);
  }

  @override
  Future<bool> isFavorite(String bookId) async {
    return _readAll().any((BookModel b) => b.id == bookId);
  }

  // --- Infra -----------------------------------------------------------------

  List<BookModel> _readAll() {
    try {
      final List<String> raw = _prefs.getStringList(favoritesKey) ?? const <String>[];

      return raw
          .map<BookModel?>((String item) {
            final Object? decoded = jsonDecode(item);
            return decoded is Map<String, dynamic> ? BookModel.fromLocalJson(decoded) : null;
          })
          .whereType<BookModel>()
          .where((BookModel b) => b.id.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      // Registro corrompido não pode derrubar a estante inteira.
      throw const CacheException('Sua estante local está corrompida.');
    } catch (_) {
      throw const CacheException();
    }
  }

  Future<void> _writeAll(List<BookModel> books) async {
    try {
      final List<String> encoded =
          books.map((BookModel b) => jsonEncode(b.toLocalJson())).toList(growable: false);

      final bool ok = await _prefs.setStringList(favoritesKey, encoded);
      if (!ok) throw const CacheException('Não foi possível salvar na sua estante.');
    } on CacheException {
      rethrow;
    } catch (_) {
      throw const CacheException('Não foi possível salvar na sua estante.');
    }
  }
}
