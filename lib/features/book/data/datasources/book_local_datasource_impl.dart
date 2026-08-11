import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/session/session_scope.dart';
import '../models/book_model.dart';
import 'book_local_datasource.dart';

/// Estante persistida em `shared_preferences` como uma lista de strings JSON.
///
/// Depende de [SharedPreferences] por injeção: trocar por Hive/Isar exige
/// apenas outra implementação de [IBookLocalDataSource].
///
/// Cada conta tem sua própria chave, derivada de [ISessionScope]: num aparelho
/// compartilhado a estante de quem sai não fica visível para quem entra.
final class BookLocalDataSourceImpl implements IBookLocalDataSource {
  const BookLocalDataSourceImpl(this._prefs, this._session);

  final SharedPreferences _prefs;
  final ISessionScope _session;

  /// Estante de quem não está autenticado. É também a chave que o app usava
  /// antes de existir login, por isso o nome sem sufixo de conta.
  static const String anonymousKey = 'libria.favorites.v1';

  /// Prefixo das estantes por conta: `libria.favorites.v1.u.<uid>`.
  static const String userKeyPrefix = 'libria.favorites.v1.u.';

  static String keyForUser(String userId) => '$userKeyPrefix$userId';

  @override
  Future<List<BookModel>> getFavorites() async => _readAll(await _resolveKey());

  @override
  Future<void> saveFavorite(BookModel book) async {
    final String key = await _resolveKey();
    final List<BookModel> favorites = _readAll(key);
    if (favorites.any((BookModel b) => b.id == book.id)) return;

    // Mais recentes primeiro: a estante reflete a ordem de adição.
    await _writeAll(key, <BookModel>[book, ...favorites]);
  }

  @override
  Future<void> removeFavorite(String bookId) async {
    final String key = await _resolveKey();
    final List<BookModel> favorites = _readAll(key);
    final List<BookModel> updated =
        favorites.where((BookModel b) => b.id != bookId).toList(growable: false);

    if (updated.length == favorites.length) return;
    await _writeAll(key, updated);
  }

  @override
  Future<bool> isFavorite(String bookId) async {
    return _readAll(await _resolveKey()).any((BookModel b) => b.id == bookId);
  }

  // --- Escopo ----------------------------------------------------------------

  /// Chave da estante do dono atual dos dados.
  ///
  /// Resolvida a cada operação, e não no construtor: a sessão muda enquanto o
  /// app está aberto, e a estante precisa acompanhar sem recriar a injeção.
  Future<String> _resolveKey() async {
    final String? userId = _session.scopeId;
    if (userId == null) return anonymousKey;

    final String key = keyForUser(userId);
    await _adoptAnonymousShelf(key);
    return key;
  }

  /// Entrega a estante pré-login para a primeira conta que entrar no aparelho.
  ///
  /// É uma mudança de dono, não uma cópia: a estante anônima é apagada, senão a
  /// segunda conta a fazer login herdaria os livros de quem usou o app antes.
  /// Uma conta que já tem estante própria nunca é sobrescrita.
  Future<void> _adoptAnonymousShelf(String userKey) async {
    if (_prefs.containsKey(userKey)) return;

    final List<String>? anonymous = _prefs.getStringList(anonymousKey);
    if (anonymous == null) return;

    if (anonymous.isNotEmpty) await _prefs.setStringList(userKey, anonymous);
    await _prefs.remove(anonymousKey);
  }

  // --- Infra -----------------------------------------------------------------

  List<BookModel> _readAll(String key) {
    try {
      final List<String> raw = _prefs.getStringList(key) ?? const <String>[];

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

  Future<void> _writeAll(String key, List<BookModel> books) async {
    try {
      final List<String> encoded =
          books.map((BookModel b) => jsonEncode(b.toLocalJson())).toList(growable: false);

      final bool ok = await _prefs.setStringList(key, encoded);
      if (!ok) throw const CacheException('Não foi possível salvar na sua estante.');
    } on CacheException {
      rethrow;
    } catch (_) {
      throw const CacheException('Não foi possível salvar na sua estante.');
    }
  }
}
