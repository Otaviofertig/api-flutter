import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/state/ui_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../controllers/favorites_controller.dart';
import '../widgets/book_grid.dart';
import '../widgets/state_view.dart';
import 'book_detail_page.dart';

/// "Minha Estante": livros salvos localmente.
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

class _FavoritesPageState extends State<FavoritesPage> {
  late final FavoritesController _controller = FavoritesController(
    sl<GetFavorites>(),
    sl<ToggleFavorite>(),
  );

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDetail(Book book) async {
    await Navigator.of(context).push(BookDetailPage.route(book));
    // O livro pode ter sido removido lá dentro: recarrega sem piscar a tela.
    if (mounted) await _controller.load(showLoading: false);
  }

  Future<void> _remove(Book book) async {
    final String message = await _controller.remove(book);
    if (!mounted || message.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final double padding = Responsive.horizontalPadding(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Estante')),
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
                  sliver: switch (_controller.state) {
                    IdleState<List<Book>>() || LoadingState<List<Book>>() =>
                      const BookGridSkeleton(itemCount: 6),
                    EmptyState<List<Book>>(:final String message) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: StateView(
                          icon: Icons.bookmarks_outlined,
                          title: 'Estante vazia',
                          message: message,
                          actionLabel: 'Buscar livros',
                          onAction: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ErrorState<List<Book>>(:final failure) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: StateView.fromFailure(failure, onRetry: _controller.load),
                      ),
                    SuccessState<List<Book>>(:final List<Book> data) => BookGrid(
                        books: data,
                        onBookTap: _openDetail,
                        trailingBuilder: (Book book) => _RemoveButton(
                          onPressed: () => _remove(book),
                        ),
                      ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Botão de remover sobreposto à capa, com contraste garantido sobre a imagem.
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: const Icon(Icons.bookmark_remove_outlined, size: 20),
        tooltip: 'Remover da estante',
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      ),
    );
  }
}
