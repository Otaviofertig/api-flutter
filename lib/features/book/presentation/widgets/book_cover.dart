import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import 'shimmer_box.dart';

/// Tamanhos de capa oferecidos pela Covers API.
enum CoverSize {
  small('S'),
  medium('M'),
  large('L');

  const CoverSize(this.code);

  final String code;
}

/// Capa de livro com cache, shimmer enquanto baixa e *placeholder* elegante
/// quando a obra não tem capa na Open Library — caso bastante comum na API.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.coverId,
    required this.title,
    this.size = CoverSize.medium,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  final int? coverId;
  final String title;
  final CoverSize size;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final String? url = ApiConstants.coverById(coverId, size: size.code);
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    if (url == null) {
      return _CoverFallback(title: title, borderRadius: borderRadius);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (BuildContext context, String _) => ShimmerBox(radius: radius),
        // A API responde 200 com um GIF de 1px quando a capa não existe;
        // o errorWidget cobre 404 e falhas de rede.
        errorWidget: (BuildContext context, String url, Object _) =>
            _CoverFallback(title: title, borderRadius: borderRadius),
      ),
    );
  }
}

/// Substituto visual da capa: iniciais do título sobre um degradê do tema.
class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.title, required this.borderRadius});

  final String title;
  final BorderRadius borderRadius;

  String get _initials {
    final List<String> words = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words[0].characters.first + words[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[scheme.secondaryContainer, scheme.surfaceContainerHighest],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.menu_book_outlined, color: scheme.onSecondaryContainer, size: 28),
            const SizedBox(height: 6),
            // FittedBox garante que as iniciais nunca estourem a caixa,
            // independentemente do tamanho do card ou da fonte do sistema.
            Flexible(
              child: FittedBox(
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSecondaryContainer,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
