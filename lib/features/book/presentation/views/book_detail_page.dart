import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/state/ui_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail.dart';
import '../../domain/entities/reading_status.dart';
import '../../domain/usecases/get_book_detail.dart';
import '../../domain/usecases/get_reading_status.dart';
import '../../domain/usecases/set_reading_status.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../controllers/book_detail_controller.dart';
import '../widgets/book_cover.dart';
import '../widgets/reading_status_menu.dart';
import '../widgets/shimmer_box.dart';
import '../widgets/state_view.dart';
import 'author_page.dart';

/// Tela de detalhes de uma obra.
///
/// A View não contém regra: assina o controller e renderiza o `UiState`.
class BookDetailPage extends StatefulWidget {
  const BookDetailPage({super.key, required this.book});

  final Book book;

  /// Rota tipada — evita `arguments` dinâmicos espalhados pelo app.
  static Route<bool> route(Book book) {
    return MaterialPageRoute<bool>(
      builder: (BuildContext _) => BookDetailPage(book: book),
      settings: RouteSettings(name: '/book/${book.id}'),
    );
  }

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late final BookDetailController _controller = BookDetailController(
    sl<GetBookDetail>(),
    sl<ToggleFavorite>(),
    sl<GetReadingStatus>(),
    sl<SetReadingStatus>(),
    widget.book,
  );

  /// Sinaliza para a tela anterior que a estante mudou.
  bool _favoritesChanged = false;

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

  Future<void> _onToggleFavorite() async {
    _showResult(await _controller.toggleFavorite());
  }

  Future<void> _onStatusChanged(ReadingStatus status) async {
    _showResult(await _controller.setStatus(status));
  }

  void _showResult(String message) {
    if (!mounted || message.isEmpty) return;

    _favoritesChanged = true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        // Devolve `true` quando a estante mudou, para quem abriu se atualizar.
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_favoritesChanged),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          return switch (_controller.state) {
            IdleState<BookDetail>() || LoadingState<BookDetail>() =>
              _DetailSkeleton(book: widget.book),
            ErrorState<BookDetail>(:final failure) =>
              StateView.fromFailure(failure, onRetry: _controller.load),
            EmptyState<BookDetail>(:final message) => StateView(
                icon: Icons.menu_book_outlined,
                title: 'Sem detalhes',
                message: message,
              ),
            SuccessState<BookDetail>(:final BookDetail data) => _DetailContent(
                detail: data,
                status: _controller.status,
                isBusy: _controller.isFavoriteBusy,
                onToggleFavorite: _onToggleFavorite,
                onStatusChanged: _onStatusChanged,
              ),
          };
        },
      ),
    );
  }
}

/// Conteúdo carregado: empilhado no celular, em duas colunas em telas largas.
class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.status,
    required this.isBusy,
    required this.onToggleFavorite,
    required this.onStatusChanged,
  });

  final BookDetail detail;

  /// `null` quando o livro não está na estante.
  final ReadingStatus? status;

  final bool isBusy;
  final VoidCallback onToggleFavorite;
  final void Function(ReadingStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final bool isWide = Responsive.sizeOf(width) != ScreenSize.compact;
        final double padding = Responsive.horizontalPadding(width);

        final Widget cover = _CoverPanel(
          detail: detail,
          status: status,
          isBusy: isBusy,
          onToggleFavorite: onToggleFavorite,
          onStatusChanged: onStatusChanged,
          maxWidth: isWide ? 260 : 200,
        );

        final Widget info = _InfoPanel(detail: detail);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xl, padding, AppSpacing.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        cover,
                        const SizedBox(width: AppSpacing.xxl),
                        Expanded(child: info),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        cover,
                        const SizedBox(height: AppSpacing.xl),
                        info,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _CoverPanel extends StatelessWidget {
  const _CoverPanel({
    required this.detail,
    required this.status,
    required this.isBusy,
    required this.onToggleFavorite,
    required this.onStatusChanged,
    required this.maxWidth,
  });

  final BookDetail detail;
  final ReadingStatus? status;
  final bool isBusy;
  final VoidCallback onToggleFavorite;
  final void Function(ReadingStatus status) onStatusChanged;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: AspectRatio(
              // Proporção típica de capa de livro.
              aspectRatio: 2 / 3,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRadius.card),
                clipBehavior: Clip.antiAlias,
                child: BookCover(
                  coverId: detail.preferredCoverId,
                  title: detail.title,
                  size: CoverSize.large,
                  radius: AppRadius.card,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: <Widget>[
                _FavoriteButton(
                  isFavorite: status != null,
                  isBusy: isBusy,
                  onPressed: onToggleFavorite,
                ),
                const SizedBox(height: AppSpacing.md),
                _StatusPicker(
                  status: status,
                  isBusy: isBusy,
                  onChanged: onStatusChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Prateleiras da estante, para marcar em que ponto da leitura o livro está.
///
/// Aparece mesmo com o livro fora da estante: escolher "Lendo" num livro que
/// se acabou de encontrar salva e marca de uma vez, sem exigir "adicionar"
/// antes.
class _StatusPicker extends StatelessWidget {
  const _StatusPicker({
    required this.status,
    required this.isBusy,
    required this.onChanged,
  });

  final ReadingStatus? status;
  final bool isBusy;
  final void Function(ReadingStatus status) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final ReadingStatus option in ReadingStatus.values)
          ChoiceChip(
            selected: option == status,
            avatar: Icon(iconForStatus(option), size: 18),
            label: Text(option.label),
            visualDensity: VisualDensity.compact,
            // Reclicar a prateleira atual não faz nada: desmarcar por aqui
            // seria ambíguo entre "tirar da estante" e "voltar ao início".
            onSelected: isBusy || option == status ? null : (_) => onChanged(option),
          ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isFavorite;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      isFavorite ? 'Na Minha Estante' : 'Adicionar à Minha Estante',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final Widget icon = isBusy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(isFavorite ? Icons.bookmark_rounded : Icons.bookmark_add_outlined);

    return SizedBox(
      width: double.infinity,
      child: isFavorite
          ? FilledButton.tonalIcon(
              onPressed: isBusy ? null : onPressed,
              icon: icon,
              label: label,
            )
          : FilledButton.icon(
              onPressed: isBusy ? null : onPressed,
              icon: icon,
              label: label,
            ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.detail});

  final BookDetail detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> subjects = detail.topSubjects();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(detail.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        _AuthorLinks(book: detail.book),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            _MetaChip(
              icon: Icons.event_outlined,
              label: '1ª edição: ${detail.book.yearLabel}',
            ),
            if (detail.book.editionCount > 0)
              _MetaChip(
                icon: Icons.layers_outlined,
                label: '${detail.book.editionCount} edições',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _Section(
          title: 'Sobre a obra',
          child: Text(
            detail.hasDescription
                ? detail.description!
                : 'A Open Library ainda não tem um resumo para esta obra.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: detail.hasDescription
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontStyle: detail.hasDescription ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
        if (subjects.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          _Section(
            title: 'Assuntos',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: subjects
                  .map((String s) => Chip(
                        label: Text(s),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }
}

/// Autores da obra, com link para a ficha de quem tem id na Open Library.
///
/// Nem todo autor tem registro próprio: quando falta o id, o nome continua
/// aparecendo como texto. Um link morto seria pior que nenhum link.
class _AuthorLinks extends StatelessWidget {
  const _AuthorLinks({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style =
        theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary);

    if (book.authors.isEmpty) {
      return Text(book.authorsLabel, style: style);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final (int index, ({String name, String? id}) author)
            in book.authorEntries.indexed) ...<Widget>[
          if (index > 0) Text(', ', style: style),
          if (author.id == null)
            Text(author.name, style: style)
          else
            InkWell(
              onTap: () => Navigator.of(context).push(
                AuthorPage.route(authorId: author.id!, authorName: author.name),
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  author.name,
                  style: style?.copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Skeleton da tela de detalhes, já com os dados que vieram da listagem.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double padding = Responsive.horizontalPadding(constraints.maxWidth);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xl, padding, AppSpacing.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: BookCover(
                          coverId: book.coverId,
                          title: book.title,
                          size: CoverSize.large,
                          radius: AppRadius.card,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const ShimmerBox(height: 28, width: 240),
                  const SizedBox(height: AppSpacing.md),
                  const ShimmerBox(height: 18, width: 160),
                  const SizedBox(height: AppSpacing.xl),
                  const ShimmerBox(height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  const ShimmerBox(height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  const ShimmerBox(height: 14, width: 220),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
