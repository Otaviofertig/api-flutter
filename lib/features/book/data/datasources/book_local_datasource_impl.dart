import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/session/session_scope.dart';
import '../../domain/entities/reading_status.dart';
import '../models/book_model.dart';
import '../models/shelf_entry_model.dart';
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
  Future<List<ShelfEntryModel>> getFavorites() async => _readAll(await _resolveKey());

  @override
  Future<void> saveFavorite(
    BookModel book, {
    ReadingStatus status = ReadingStatus.initial,
  }) async {
    final String key = await _resolveKey();
    final List<ShelfEntryModel> shelf = _readAll(key);

    // Salvar de novo não reescreve o status: quem já marcou "Lido" não perde
    // a marcação por tocar em "adicionar" outra vez.
    if (shelf.any((ShelfEntryModel e) => e.id == book.id)) return;

    final ShelfEntryModel entry = ShelfEntryModel(book: book, status: status);

    // Mais recentes primeiro: a estante reflete a ordem de adição.
    await _writeAll(key, <ShelfEntryModel>[entry, ...shelf]);
  }

  @override
  Future<void> removeFavorite(String bookId) async {
    final String key = await _resolveKey();
    final List<ShelfEntryModel> shelf = _readAll(key);
    final List<ShelfEntryModel> updated =
        shelf.where((ShelfEntryModel e) => e.id != bookId).toList(growable: false);

    if (updated.length == shelf.length) return;
    await _writeAll(key, updated);
  }

  @override
  Future<bool> isFavorite(String bookId) async {
    return _readAll(await _resolveKey()).any((ShelfEntryModel e) => e.id == bookId);
  }

  @override
  Future<void> setStatus(String bookId, ReadingStatus status) async {
    final String key = await _resolveKey();
    final List<ShelfEntryModel> shelf = _readAll(key);

    bool changed = false;
    final List<ShelfEntryModel> updated = shelf.map((ShelfEntryModel entry) {
      if (entry.id != bookId || entry.status == status) return entry;
      changed = true;
      return entry.withStatus(status);
    }).toList(growable: false);

    // Nada mudou: não gasta escrita em disco.
    if (!changed) return;
    await _writeAll(key, updated);
  }

  @override
  Future<ReadingStatus?> statusOf(String bookId) async {
    for (final ShelfEntryModel entry in _readAll(await _resolveKey())) {
      if (entry.id == bookId) return entry.status;
    }
    return null;
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

  List<ShelfEntryModel> _readAll(String key) {
    try {
      final List<String> raw = _prefs.getStringList(key) ?? const <String>[];

      return raw
          .map<ShelfEntryModel?>((String item) {
            final Object? decoded = jsonDecode(item);
            return decoded is Map<String, dynamic>
                ? ShelfEntryModel.fromLocalJson(decoded)
                : null;
          })
          .whereType<ShelfEntryModel>()
          .where((ShelfEntryModel e) => e.id.isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      // Registro corrompido não pode derrubar a estante inteira.
      throw const CacheException('Sua estante local está corrompida.');
    } catch (_) {
      throw const CacheException();
    }
  }

  Future<void> _writeAll(String key, List<ShelfEntryModel> shelf) async {
    try {
      final List<String> encoded = shelf
          .map((ShelfEntryModel e) => jsonEncode(e.toLocalJson()))
          .toList(growable: false);

      final bool ok = await _prefs.setStringList(key, encoded);
      if (!ok) throw const CacheException('Não foi possível salvar na sua estante.');
    } on CacheException {
      rethrow;
    } catch (_) {
      throw const CacheException('Não foi possível salvar na sua estante.');
    }
  }
}
