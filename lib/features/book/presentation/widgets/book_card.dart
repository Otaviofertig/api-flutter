import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/book.dart';
import 'book_cover.dart';

/// Card de livro usado na busca e na estante.
///
/// A altura é definida pelo grid (`mainAxisExtent`); aqui a capa fica em
/// proporção fixa e o bloco de texto ocupa o restante.
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.trailing,
  });

  final Book book;
  final VoidCallback onTap;

  /// Ação opcional sobreposta à capa (ex.: remover da estante).
  final Widget? trailing;

  /// Proporção clássica de capa de livro.
  static const double coverAspectRatio = 2 / 3;

  /// Altura reservada para título, autor e ano, antes da escala de fonte.
  static const double textBlockHeight = 96;

  /// Altura total de um card com [width] de largura, respeitando o tamanho
  /// de fonte escolhido pelo usuário no sistema.
  static double heightFor(BuildContext context, double width) {
    return width / coverAspectRatio +
        MediaQuery.textScalerOf(context).scale(textBlockHeight);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: coverAspectRatio,
                  child: BookCover(
                    coverId: book.coverId,
                    title: book.title,
                    radius: 0,
                  ),
                ),
                if (trailing != null) Positioned(top: 4, right: 4, child: trailing!),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      book.authorsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            book.yearLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
