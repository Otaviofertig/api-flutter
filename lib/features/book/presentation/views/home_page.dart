import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/state/ui_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/theme_mode_button.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/user_menu.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/get_trending_books.dart';
import '../../domain/usecases/search_books.dart';
import '../controllers/home_controller.dart';
import '../widgets/book_grid.dart';
import '../widgets/search_field.dart';
import '../widgets/state_view.dart';
import 'book_detail_page.dart';
import 'favorites_page.dart';

/// Tela principal: busca de livros na Open Library.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller = HomeController(
    sl<SearchBooks>(),
    trendingBooks: sl<GetTrendingBooks>(),
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller.loadHighlights();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Paginação infinita: pede a próxima página ao chegar perto do fim.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _controller.loadMore();
    }
  }

  Future<void> _openDetail(Book book) async {
    await Navigator.of(context).push(BookDetailPage.route(book));
  }

  Future<void> _openFavorites() async {
    await Navigator.of(context).push(FavoritesPage.route());
  }

  @override
  Widget build(BuildContext context) {
    final double padding = Responsive.horizontalPadding(MediaQuery.sizeOf(context).width);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          // Mantém o teclado fechável ao arrastar a lista.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              titleSpacing: padding,
              title: const _Brand(),
              toolbarHeight: 64,
              actions: <Widget>[
                ThemeModeButton(controller: sl<ThemeController>()),
                IconButton(
                  icon: const Icon(Icons.bookmarks_outlined),
                  tooltip: 'Minha Estante',
                  onPressed: _openFavorites,
                ),
                // Some sozinho quando não há sessão ativa.
                UserMenu(controller: sl<AuthController>()),
                SizedBox(width: padding - AppSpacing.sm),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, AppSpacing.md),
                  child: SearchField(
                    onChanged: _controller.onQueryChanged,
                    onSubmitted: _controller.searchNow,
                    onCleared: _controller.clear,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, AppSpacing.xxl),
              sliver: ListenableBuilder(
                listenable: _controller,
                builder: (BuildContext context, Widget? _) => _HomeBody(
                  controller: _controller,
                  onBookTap: _openDetail,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Corpo da Home: um sliver por estado da tela.
class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.controller, required this.onBookTap});

  final HomeController controller;
  final void Function(Book book) onBookTap;

  @override
  Widget build(BuildContext context) {
    return switch (controller.state) {
      // Sem busca digitada, a Home é vitrine — não um campo de texto esperando.
      IdleState<List<Book>>() => _HighlightsSliver(
          state: controller.highlights,
          onBookTap: onBookTap,
        ),
      LoadingState<List<Book>>() => const BookGridSkeleton(),
      EmptyState<List<Book>>(:final String message) => SliverFillRemaining(
          hasScrollBody: false,
          child: StateView(
            icon: Icons.search_off_rounded,
            title: 'Nada encontrado',
            message: message,
          ),
        ),
      ErrorState<List<Book>>(:final failure) => SliverFillRemaining(
          hasScrollBody: false,
          child: StateView.fromFailure(failure, onRetry: controller.search),
        ),
      SuccessState<List<Book>>(:final List<Book> data) => _ResultsSliver(
          books: data,
          isLoadingMore: controller.isLoadingMore,
          onBookTap: onBookTap,
        ),
    };
  }
}

/// Vitrine de obras em alta, mostrada enquanto ninguém digitou nada.
///
/// Falha e vazio caem no convite de busca original em vez de mostrar erro: a
/// vitrine é um extra, e quem abriu o app para procurar um título específico
/// não deveria levar uma tela de erro por causa dela.
class _HighlightsSliver extends StatelessWidget {
  const _HighlightsSliver({required this.state, required this.onBookTap});

  final UiState<List<Book>> state;
  final void Function(Book book) onBookTap;

  static const Widget _invite = SliverFillRemaining(
    hasScrollBody: false,
    child: StateView(
      icon: Icons.auto_stories_outlined,
      title: 'O que você quer ler hoje?',
      message: 'Busque por título, autor ou ISBN e explore o acervo da Open Library.',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      IdleState<List<Book>>() ||
      EmptyState<List<Book>>() ||
      ErrorState<List<Book>>() =>
        _invite,
      LoadingState<List<Book>>() => const SliverMainAxisGroup(
          slivers: <Widget>[_HighlightsHeader(), BookGridSkeleton(itemCount: 6)],
        ),
      SuccessState<List<Book>>(:final List<Book> data) => SliverMainAxisGroup(
          slivers: <Widget>[
            const _HighlightsHeader(),
            BookGrid(books: data, onBookTap: onBookTap),
          ],
        ),
    };
  }
}

class _HighlightsHeader extends StatelessWidget {
  const _HighlightsHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.local_fire_department_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Em alta hoje',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid de resultados + rodapé de carregamento da próxima página.
class _ResultsSliver extends StatelessWidget {
  const _ResultsSliver({
    required this.books,
    required this.isLoadingMore,
    required this.onBookTap,
  });

  final List<Book> books;
  final bool isLoadingMore;
  final void Function(Book book) onBookTap;

  @override
  Widget build(BuildContext context) {
    // Um sliver por vez: o grid e, abaixo dele, o indicador de paginação.
    return SliverMainAxisGroup(
      slivers: <Widget>[
        BookGrid(books: books, onBookTap: onBookTap),
        SliverToBoxAdapter(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              height: isLoadingMore ? 72 : 0,
              child: const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Marca do app no topo da Home.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.local_library_rounded, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Libria',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Seu guia literário',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
