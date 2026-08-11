import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverConstraints;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/book.dart';
import 'book_card.dart';
import 'shimmer_box.dart';

/// Grid responsivo de livros, em forma de sliver.
///
/// O número de colunas vem da largura real disponível (não de um breakpoint
/// fixo), e a altura do card é calculada a partir da largura da coluna e da
/// escala de fonte do sistema — nada de proporção mágica que estoura em
/// telas pequenas ou com fonte grande.
class BookGrid extends StatelessWidget {
  const BookGrid({
    super.key,
    required this.books,
    required this.onBookTap,
    this.trailingBuilder,
    this.spacing = AppSpacing.md,
  });

  final List<Book> books;
  final void Function(Book book) onBookTap;
  final Widget Function(Book book)? trailingBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double width = constraints.crossAxisExtent;
        final int columns = Responsive.columnsFor(width, spacing: spacing);
        final double itemWidth = (width - spacing * (columns - 1)) / columns;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: BookCard.heightFor(context, itemWidth),
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final Book book = books[index];
              return BookCard(
                book: book,
                onTap: () => onBookTap(book),
                trailing: trailingBuilder?.call(book),
              );
            },
            childCount: books.length,
          ),
        );
      },
    );
  }
}

/// Skeleton com a mesma métrica do [BookGrid], para a transição não "pular".
class BookGridSkeleton extends StatelessWidget {
  const BookGridSkeleton({super.key, this.itemCount = 8, this.spacing = AppSpacing.md});

  final int itemCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double width = constraints.crossAxisExtent;
        final int columns = Responsive.columnsFor(width, spacing: spacing);
        final double itemWidth = (width - spacing * (columns - 1)) / columns;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: BookCard.heightFor(context, itemWidth),
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => const _BookCardSkeleton(),
            childCount: itemCount,
          ),
        );
      },
    );
  }
}

class _BookCardSkeleton extends StatelessWidget {
  const _BookCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AspectRatio(
            aspectRatio: BookCard.coverAspectRatio,
            child: ShimmerBox(radius: 0),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const ShimmerBox(height: 12),
                  const SizedBox(height: AppSpacing.sm),
                  const ShimmerBox(height: 12, width: 80),
                  const Spacer(),
                  const ShimmerBox(height: 10, width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
