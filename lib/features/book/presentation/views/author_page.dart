import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/state/ui_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../../domain/usecases/get_author.dart';
import '../../domain/usecases/get_author_works.dart';
import '../controllers/author_controller.dart';
import '../widgets/book_grid.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/state_view.dart';
import 'book_detail_page.dart';

/// Ficha do autor: biografia e bibliografia paginada.
class AuthorPage extends StatefulWidget {
  const AuthorPage({super.key, required this.authorId, required this.authorName});

  final String authorId;

  /// Nome já conhecido pela tela anterior — vira título imediato, sem esperar
  /// a requisição da ficha.
  final String authorName;

  static Route<void> route({required String authorId, required String authorName}) {
    return MaterialPageRoute<void>(
      builder: (BuildContext _) => AuthorPage(authorId: authorId, authorName: authorName),
      settings: RouteSettings(name: '/author/$authorId'),
    );
  }

  @override
  State<AuthorPage> createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  late final AuthorController _controller = AuthorController(
    sl<GetAuthor>(),
    sl<GetAuthorWorks>(),
    authorId: widget.authorId,
    authorName: widget.authorName,
  );

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller.load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _controller.loadMore();
    }
  }

  Future<void> _openBook(Book book) async {
    await Navigator.of(context).push(BookDetailPage.route(book));
  }

  @override
  Widget build(BuildContext context) {
    final double padding = Responsive.horizontalPadding(MediaQuery.sizeOf(context).width);

    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                title: Text(_controller.displayName, overflow: TextOverflow.ellipsis),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, AppSpacing.lg, padding, AppSpacing.xxl),
                sliver: SliverMainAxisGroup(
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: _AuthorHeader(
                        state: _controller.author,
                        fallbackName: widget.authorName,
                        onRetry: _controller.loadAuthor,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                    _WorksSection(
                      state: _controller.works,
                      isLoadingMore: _controller.isLoadingMore,
                      onBookTap: _openBook,
                      onRetry: _controller.loadWorks,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Retrato, nome, datas e biografia.
///
/// Falha aqui não vira tela de erro: o nome herdado da tela anterior já
/// sustenta a página, e a bibliografia abaixo continua valendo.
class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({
    required this.state,
    required this.fallbackName,
    required this.onRetry,
  });

  final UiState<Author> state;
  final String fallbackName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      IdleState<Author>() || LoadingState<Author>() => const _HeaderSkeleton(),
      ErrorState<Author>() || EmptyState<Author>() => _HeaderFallback(
          name: fallbackName,
          onRetry: onRetry,
        ),
      SuccessState<Author>(:final Author data) => _HeaderContent(author: data),
    };
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? lifespan = author.lifespanLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AuthorPortrait(author: author),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    author.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (lifespan != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      lifespan,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (author.hasBio) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Text(
            author.bio!,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _AuthorPortrait extends StatelessWidget {
  const _AuthorPortrait({required this.author});

  final Author author;

  static const double _size = 88;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? photo = ApiConstants.authorPhotoById(author.photoId);

    final Widget initials = Center(
      child: Text(
        author.initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: _size,
        child: ColoredBox(
          color: scheme.primaryContainer,
          // Sem retrato, ou com o retrato falhando, as iniciais seguram o
          // lugar: nada de buraco cinza no topo da ficha.
          child: photo == null
              ? initials
              : CachedNetworkImage(
                  imageUrl: photo,
                  fit: BoxFit.cover,
                  placeholder: (BuildContext _, String _) => initials,
                  errorWidget: (BuildContext _, String _, Object _) => initials,
                ),
        ),
      ),
    );
  }
}

/// Cabeçalho quando a ficha falhou: mantém o nome e oferece nova tentativa.
class _HeaderFallback extends StatelessWidget {
  const _HeaderFallback({required this.name, required this.onRetry});

  final String name;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style:
                    theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Não foi possível carregar a biografia.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar de novo'),
        ),
      ],
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ShimmerBox(height: 88, width: 88, radius: AppRadius.pill),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const ShimmerBox(height: 26, width: 200),
              const SizedBox(height: AppSpacing.sm),
              const ShimmerBox(height: 14, width: 130),
              const SizedBox(height: AppSpacing.lg),
              const ShimmerBox(height: 12),
              const SizedBox(height: AppSpacing.sm),
              const ShimmerBox(height: 12, width: 240),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bibliografia: título de seção + grid + rodapé de paginação.
class _WorksSection extends StatelessWidget {
  const _WorksSection({
    required this.state,
    required this.isLoadingMore,
    required this.onBookTap,
    required this.onRetry,
  });

  final UiState<List<Book>> state;
  final bool isLoadingMore;
  final void Function(Book book) onBookTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget title = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          'Obras',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return SliverMainAxisGroup(
      slivers: <Widget>[
        title,
        switch (state) {
          IdleState<List<Book>>() || LoadingState<List<Book>>() =>
            const BookGridSkeleton(itemCount: 6),
          EmptyState<List<Book>>(:final String message) => SliverToBoxAdapter(
              child: StateView(
                icon: Icons.menu_book_outlined,
                title: 'Sem obras listadas',
                message: message,
              ),
            ),
          ErrorState<List<Book>>(:final failure) => SliverToBoxAdapter(
              child: StateView.fromFailure(failure, onRetry: onRetry),
            ),
          SuccessState<List<Book>>(:final List<Book> data) =>
            BookGrid(books: data, onBookTap: onBookTap),
        },
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
