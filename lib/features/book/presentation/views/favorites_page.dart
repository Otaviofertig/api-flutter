import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/state/ui_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/entities/shelf_entry.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/set_reading_status.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../controllers/favorites_controller.dart';
import '../widgets/book_grid.dart';
import '../widgets/reading_status_menu.dart';
import '../widgets/state_view.dart';
import 'book_detail_page.dart';

/// "Minha Estante": livros salvos localmente, separados por ponto de leitura.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (BuildContext _) => const FavoritesPage(),
      settings: const RouteSettings(name: '/estante'),
    );
  }

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final FavoritesController _controller = FavoritesController(
    sl<GetFavorites>(),
    sl<ToggleFavorite>(),
    sl<SetReadingStatus>(),
  );

  /// Índice 0 é "Todos"; os demais seguem a ordem de `ReadingStatus.values`.
  late final TabController _tabs = TabController(
    length: ReadingStatus.values.length + 1,
    vsync: this,
  )..addListener(_onTabChanged);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // `indexIsChanging` é `true` no meio da animação de arrasto: filtrar ali
    // trocaria a lista embaixo do dedo antes de a aba assentar.
    if (_tabs.indexIsChanging) return;

    _controller.setFilter(
      _tabs.index == 0 ? null : ReadingStatus.values[_tabs.index - 1],
    );
  }

  Future<void> _openDetail(Book book) async {
    await Navigator.of(context).push(BookDetailPage.route(book));
    // O livro pode ter sido removido ou remarcado lá dentro: recarrega sem
    // piscar a tela.
    if (mounted) await _controller.load(showLoading: false);
  }

  Future<void> _remove(Book book) async {
    _showMessage(await _controller.remove(book));
  }

  Future<void> _changeStatus(ShelfEntry entry, ReadingStatus status) async {
    _showMessage(await _controller.changeStatus(entry, status));
  }

  void _showMessage(String message) {
    if (!mounted || message.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final double padding = Responsive.horizontalPadding(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Estante'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: <Widget>[
            ListenableBuilder(
              listenable: _controller,
              builder: (BuildContext context, Widget? _) =>
                  Tab(text: 'Todos (${_controller.total})'),
            ),
            for (final ReadingStatus status in ReadingStatus.values)
              ListenableBuilder(
                listenable: _controller,
                builder: (BuildContext context, Widget? _) =>
                    Tab(text: '${status.label} (${_controller.counts[status] ?? 0})'),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.load(showLoading: false),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (BuildContext context, Widget? _) {
            return CustomScrollView(
              // Garante que o pull-to-refresh funcione mesmo com a tela vazia.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding:
                      EdgeInsets.fromLTRB(padding, AppSpacing.lg, padding, AppSpacing.xxl),
                  sliver: _ShelfSliver(
                    controller: _controller,
                    onBookTap: _openDetail,
                    onRemove: _remove,
                    onChangeStatus: _changeStatus,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Corpo da estante: um sliver por estado, com o filtro de prateleira já
/// aplicado.
class _ShelfSliver extends StatelessWidget {
  const _ShelfSliver({
    required this.controller,
    required this.onBookTap,
    required this.onRemove,
    required this.onChangeStatus,
  });

  final FavoritesController controller;
  final void Function(Book book) onBookTap;
  final void Function(Book book) onRemove;
  final void Function(ShelfEntry entry, ReadingStatus status) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return switch (controller.state) {
      IdleState<List<ShelfEntry>>() || LoadingState<List<ShelfEntry>>() =>
        const BookGridSkeleton(itemCount: 6),
      EmptyState<List<ShelfEntry>>(:final String message) => SliverFillRemaining(
          hasScrollBody: false,
          child: StateView(
            icon: Icons.bookmarks_outlined,
            title: 'Estante vazia',
            message: message,
            actionLabel: 'Buscar livros',
            onAction: () => Navigator.of(context).pop(),
          ),
        ),
      ErrorState<List<ShelfEntry>>(:final failure) => SliverFillRemaining(
          hasScrollBody: false,
          child: StateView.fromFailure(failure, onRetry: controller.load),
        ),
      SuccessState<List<ShelfEntry>>() => _ShelfGrid(
          controller: controller,
          onBookTap: onBookTap,
          onRemove: onRemove,
          onChangeStatus: onChangeStatus,
        ),
    };
  }
}

class _ShelfGrid extends StatelessWidget {
  const _ShelfGrid({
    required this.controller,
    required this.onBookTap,
    required this.onRemove,
    required this.onChangeStatus,
  });

  final FavoritesController controller;
  final void Function(Book book) onBookTap;
  final void Function(Book book) onRemove;
  final void Function(ShelfEntry entry, ReadingStatus status) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final List<ShelfEntry> entries = controller.visibleEntries;

    // A estante tem livros, mas nenhum nesta prateleira: estado diferente de
    // "estante vazia", e merece texto diferente.
    if (entries.isEmpty) {
      final String label = controller.filter?.label ?? '';

      return SliverFillRemaining(
        hasScrollBody: false,
        child: StateView(
          icon: Icons.filter_list_off_rounded,
          title: 'Nada em "$label"',
          message: 'Nenhum livro da sua estante está marcado como "$label".',
        ),
      );
    }

    final Map<String, ShelfEntry> byId = <String, ShelfEntry>{
      for (final ShelfEntry entry in entries) entry.id: entry,
    };

    return BookGrid(
      books: entries.map((ShelfEntry e) => e.book).toList(growable: false),
      onBookTap: onBookTap,
      trailingBuilder: (Book book) {
        final ShelfEntry? entry = byId[book.id];
        if (entry == null) return const SizedBox.shrink();

        return ReadingStatusMenu(
          status: entry.status,
          onSelected: (ReadingStatus status) => onChangeStatus(entry, status),
          onRemove: () => onRemove(book),
        );
      },
    );
  }
}
