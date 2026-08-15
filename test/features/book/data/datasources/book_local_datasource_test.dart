import 'package:flutter_test/flutter_test.dart';
import 'package:libria/core/session/session_scope.dart';
import 'package:libria/features/book/data/datasources/book_local_datasource_impl.dart';
import 'package:libria/features/book/data/models/book_model.dart';
import 'package:libria/features/book/data/models/shelf_entry_model.dart';
import 'package:libria/features/book/domain/entities/reading_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sessão controlável: reproduz login, logout e troca de conta em runtime.
class _FakeSessionScope implements ISessionScope {
  _FakeSessionScope([this.scopeId]);

  @override
  String? scopeId;
}

const BookModel _dune = BookModel(id: 'OL1W', title: 'Duna');
const BookModel _hobbit = BookModel(id: 'OL2W', title: 'O Hobbit');

Future<BookLocalDataSourceImpl> _sourceFor(_FakeSessionScope session) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return BookLocalDataSourceImpl(prefs, session);
}

Future<List<String>> _idsIn(BookLocalDataSourceImpl source) async {
  final List<ShelfEntryModel> shelf = await source.getFavorites();
  return shelf.map((ShelfEntryModel e) => e.id).toList(growable: false);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('cada conta tem a sua estante: a de uma não aparece na da outra', () async {
    final _FakeSessionScope session = _FakeSessionScope('user-a');
    final BookLocalDataSourceImpl source = await _sourceFor(session);

    await source.saveFavorite(_dune);

    session.scopeId = 'user-b';
    expect(await _idsIn(source), isEmpty);
    expect(await source.isFavorite(_dune.id), isFalse);

    await source.saveFavorite(_hobbit);

    session.scopeId = 'user-a';
    expect(await _idsIn(source), <String>[_dune.id]);
  });

  test('remover na conta de um usuário não toca na estante do outro', () async {
    final _FakeSessionScope session = _FakeSessionScope('user-a');
    final BookLocalDataSourceImpl source = await _sourceFor(session);

    await source.saveFavorite(_dune);

    session.scopeId = 'user-b';
    await source.saveFavorite(_dune);
    await source.removeFavorite(_dune.id);
    expect(await _idsIn(source), isEmpty);

    session.scopeId = 'user-a';
    expect(await _idsIn(source), <String>[_dune.id]);
  });

  test('sem sessão, a estante fica na chave do aparelho', () async {
    final _FakeSessionScope session = _FakeSessionScope();
    final BookLocalDataSourceImpl source = await _sourceFor(session);

    await source.saveFavorite(_dune);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(BookLocalDataSourceImpl.anonymousKey), isTrue);
    expect(await _idsIn(source), <String>[_dune.id]);
  });

  group('estante criada antes do login', () {
    test('vai para a primeira conta que entra no aparelho', () async {
      final _FakeSessionScope session = _FakeSessionScope();
      final BookLocalDataSourceImpl source = await _sourceFor(session);

      await source.saveFavorite(_dune);

      session.scopeId = 'user-a';
      expect(await _idsIn(source), <String>[_dune.id]);

      // Mudança de dono, não cópia: a chave do aparelho deixa de existir.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(BookLocalDataSourceImpl.anonymousKey), isFalse);
      expect(prefs.containsKey(BookLocalDataSourceImpl.keyForUser('user-a')), isTrue);
    });

    test('não é herdada pela segunda conta', () async {
      final _FakeSessionScope session = _FakeSessionScope();
      final BookLocalDataSourceImpl source = await _sourceFor(session);

      await source.saveFavorite(_dune);

      session.scopeId = 'user-a';
      await source.getFavorites(); // adota

      session.scopeId = 'user-b';
      expect(await _idsIn(source), isEmpty);
    });

    test('não sobrescreve a estante de uma conta que já tem livros', () async {
      final _FakeSessionScope session = _FakeSessionScope('user-a');
      final BookLocalDataSourceImpl source = await _sourceFor(session);

      await source.saveFavorite(_hobbit);

      session.scopeId = null;
      await source.saveFavorite(_dune);

      session.scopeId = 'user-a';
      expect(await _idsIn(source), <String>[_hobbit.id]);
    });
  });

  group('status de leitura', () {
    test('livro salvo entra em "Quero ler"', () async {
      final BookLocalDataSourceImpl source = await _sourceFor(_FakeSessionScope());

      await source.saveFavorite(_dune);

      expect(await source.statusOf(_dune.id), ReadingStatus.wantToRead);
    });

    test('salvar já marcando a prateleira respeita a escolha', () async {
      final BookLocalDataSourceImpl source = await _sourceFor(_FakeSessionScope());

      await source.saveFavorite(_dune, status: ReadingStatus.reading);

      expect(await source.statusOf(_dune.id), ReadingStatus.reading);
    });

    test('salvar de novo não reescreve o status já marcado', () async {
      final BookLocalDataSourceImpl source = await _sourceFor(_FakeSessionScope());

      await source.saveFavorite(_dune);
      await source.setStatus(_dune.id, ReadingStatus.read);
      // Quem já terminou o livro não pode perder a marcação por tocar de novo
      // em "adicionar".
      await source.saveFavorite(_dune, status: ReadingStatus.wantToRead);

      expect(await source.statusOf(_dune.id), ReadingStatus.read);
    });

    test('mudar de prateleira sobrevive à releitura', () async {
      final _FakeSessionScope session = _FakeSessionScope('user-a');
      final BookLocalDataSourceImpl source = await _sourceFor(session);

      await source.saveFavorite(_dune);
      await source.setStatus(_dune.id, ReadingStatus.reading);

      final BookLocalDataSourceImpl reopened = await _sourceFor(session);
      expect(await reopened.statusOf(_dune.id), ReadingStatus.reading);
    });

    test('marcar livro fora da estante não o adiciona', () async {
      final BookLocalDataSourceImpl source = await _sourceFor(_FakeSessionScope());

      await source.setStatus('OL999W', ReadingStatus.read);

      expect(await _idsIn(source), isEmpty);
      expect(await source.statusOf('OL999W'), isNull);
    });

    test('a estante gravada antes desta feature volta em "Quero ler"', () async {
      // Formato antigo: o livro sem a chave `status`. Nada de migração — o
      // parser trata a ausência como o estado inicial.
      SharedPreferences.setMockInitialValues(<String, Object>{
        BookLocalDataSourceImpl.anonymousKey: <String>[
          '{"id":"OL1W","title":"Duna","authors":["Herbert"]}',
        ],
      });
      final BookLocalDataSourceImpl source = await _sourceFor(_FakeSessionScope());

      final List<ShelfEntryModel> shelf = await source.getFavorites();

      expect(shelf.single.id, 'OL1W');
      expect(shelf.single.status, ReadingStatus.wantToRead);
      expect(shelf.single.book.title, 'Duna');
    });

    test('status desconhecido no disco cai no estado inicial', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        BookLocalDataSourceImpl.anonymousKey: <String>[
          '{"id":"OL1W","title":"Duna","status":"prateleira_que_nao_existe"}',
        ],
      });
      final BookLocalDataSourceImpl source = await _sourceFor(_FakeSessionScope());

      expect(await source.statusOf('OL1W'), ReadingStatus.wantToRead);
    });
  });

  test('a estante esvaziada pelo usuário não volta a ser preenchida', () async {
    final _FakeSessionScope session = _FakeSessionScope();
    final BookLocalDataSourceImpl source = await _sourceFor(session);

    await source.saveFavorite(_dune);

    session.scopeId = 'user-a';
    await source.removeFavorite(_dune.id);
    expect(await _idsIn(source), isEmpty);

    // Reabrir o app não pode ressuscitar o livro a partir da chave antiga.
    final BookLocalDataSourceImpl reopened = await _sourceFor(session);
    expect(await _idsIn(reopened), isEmpty);
  });
}
