import 'package:flutter/widgets.dart';

/// Faixas de largura usadas para adaptar o layout.
enum ScreenSize { compact, medium, expanded }

/// Helpers de responsividade baseados em breakpoints do Material 3.
abstract final class Responsive {
  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 900;

  /// Largura-alvo de um card de livro; o grid deriva as colunas a partir dela.
  static const double bookCardTargetWidth = 180;
  static const double maxContentWidth = 1100;

  static ScreenSize sizeOf(double width) {
    if (width >= expandedBreakpoint) return ScreenSize.expanded;
    if (width >= mediumBreakpoint) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  static ScreenSize of(BuildContext context) => sizeOf(MediaQuery.sizeOf(context).width);

  /// Nº de colunas que cabe em [width], respeitando um mínimo/máximo sensato.
  ///
  /// Preferido a valores fixos por breakpoint: funciona igual em telas
  /// estreitas, tablets e janelas redimensionáveis (desktop/web).
  static int columnsFor(double width, {double target = bookCardTargetWidth, double spacing = 12}) {
    final int columns = ((width + spacing) / (target + spacing)).floor();
    return columns.clamp(2, 6);
  }

  /// Padding horizontal proporcional à largura disponível.
  static double horizontalPadding(double width) {
    return switch (sizeOf(width)) {
      ScreenSize.compact => 16,
      ScreenSize.medium => 24,
      ScreenSize.expanded => 32,
    };
  }
}
