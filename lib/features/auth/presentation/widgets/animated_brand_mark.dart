import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Marca do Libria com a animação de entrada da tela de login.
///
/// A sequência conta a mesma história do produto: o livro **abre** e uma
/// página **vira**, enquanto o nome sobe atrás. Tudo sai de um único
/// [AnimationController] com [Interval]s — um relógio só mantém as etapas em
/// fase, o que um controller por elemento não garante.
///
/// O livro é desenhado em [CustomPainter], não é um ícone: um glifo do
/// Material não abre. As cores saem do `ColorScheme`, então a marca acompanha
/// tema claro e escuro sem nenhuma cor fixa aqui dentro.
class AnimatedBrandMark extends StatefulWidget {
  const AnimatedBrandMark({
    super.key,
    this.title = 'Libria',
    this.subtitle = 'Seu guia literário',
    this.markSize = 92,
  });

  final String title;
  final String subtitle;

  /// Diâmetro do círculo. O livro e os halos derivam daqui.
  final double markSize;

  @override
  State<AnimatedBrandMark> createState() => _AnimatedBrandMarkState();
}

class _AnimatedBrandMarkState extends State<AnimatedBrandMark>
    with TickerProviderStateMixin {
  /// Entrada, tocada uma vez.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  /// Respiro contínuo depois que a marca assenta. Amplitude baixa de
  /// propósito: numa tela de login o movimento eterno vira ruído.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Acessibilidade: com "reduzir movimento" ligado no sistema, a marca
    // aparece no estado final em vez de animar. Nada de conteúdo se perde —
    // a animação é decorativa, e quem pediu menos movimento recebe menos.
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      return;
    }

    _intro.forward();
    _idle.repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// Fatia do [_intro] entre [begin] e [end], já com a curva aplicada.
  double _stage(double begin, double end, Curve curve) {
    return Interval(begin, end, curve: curve).transform(_intro.value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_intro, _idle]),
      builder: (BuildContext context, Widget? child) {
        final double circle = _stage(0, 0.42, Curves.easeOutBack);
        final double halo = _stage(0.16, 0.95, Curves.easeOutCubic);
        final double open = _stage(0.30, 0.72, Curves.easeOutCubic);
        final double turn = _stage(0.66, 1, Curves.easeInOutCubic);
        final double title = _stage(0.44, 0.82, Curves.easeOutCubic);
        final double subtitle = _stage(0.56, 0.94, Curves.easeOutCubic);

        // Só flutua depois da entrada, senão os dois movimentos brigam.
        final double float = math.sin(_idle.value * math.pi) * 2.5 * circle;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Transform.translate(
              offset: Offset(0, -float),
              child: _mark(scheme, circle: circle, halo: halo, open: open, turn: turn),
            ),
            const SizedBox(height: AppSpacing.md),
            _reveal(
              progress: title,
              child: Text(
                widget.title,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            _reveal(
              progress: subtitle,
              child: Text(
                widget.subtitle,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mark(
    ColorScheme scheme, {
    required double circle,
    required double halo,
    required double open,
    required double turn,
  }) {
    return Opacity(
      opacity: circle.clamp(0, 1),
      child: Transform.scale(
        scale: 0.74 + 0.26 * circle,
        child: SizedBox.square(
          dimension: widget.markSize,
          child: Stack(
            alignment: Alignment.center,
            // Os halos passam do círculo — sem isso o Stack os corta.
            clipBehavior: Clip.none,
            children: <Widget>[
              _halo(scheme, halo, delay: 0),
              _halo(scheme, halo, delay: 0.3),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.expand(),
              ),
              Padding(
                padding: EdgeInsets.all(widget.markSize * 0.26),
                child: CustomPaint(
                  painter: _BookPainter(
                    open: open,
                    turn: turn,
                    ink: scheme.onPrimaryContainer,
                    page: Color.lerp(scheme.surface, scheme.primaryContainer, 0.2)!,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Anel que expande e some, como a onda de um livro tirado da estante.
  Widget _halo(ColorScheme scheme, double progress, {required double delay}) {
    final double local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
    if (local == 0 || local == 1) return const SizedBox.shrink();

    return Transform.scale(
      scale: 1 + 0.55 * local,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.primary.withValues(alpha: (1 - local) * 0.35),
            width: 1.5,
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  /// Sobe e revela — o deslocamento morre junto com a opacidade.
  Widget _reveal({required double progress, required Widget child}) {
    return Opacity(
      opacity: progress.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - progress)),
        child: child,
      ),
    );
  }
}

/// Livro aberto desenhado à mão, com uma página virando.
///
/// [open] leva as duas folhas de fechadas (largura zero, tudo na lombada) a
/// abertas. [turn] move uma página da direita para a esquerda passando pela
/// vertical — em `0.5` ela fica de perfil e some, que é o que o olho espera
/// de uma folha girando.
class _BookPainter extends CustomPainter {
  const _BookPainter({
    required this.open,
    required this.turn,
    required this.ink,
    required this.page,
  });

  final double open;
  final double turn;
  final Color ink;
  final Color page;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double halfW = size.width * 0.46;
    final double halfH = size.height * 0.40;

    final Paint fill = Paint()..color = page;
    final Paint stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final double side in <double>[-1, 1]) {
      final Path sheet = _sheet(center, halfW, halfH, side, open);
      canvas
        ..drawPath(sheet, fill)
        ..drawPath(sheet, stroke);
      _lines(canvas, size, center, halfW, halfH, side);
    }

    // A página que vira passa por cima das duas paradas.
    final double signed = 1 - 2 * turn;
    if (turn > 0 && signed.abs() > 0.02) {
      final Path flipping = _sheet(
        center,
        halfW,
        halfH,
        signed.isNegative ? -1 : 1,
        open * signed.abs(),
      );
      canvas
        ..drawPath(flipping, fill)
        ..drawPath(flipping, stroke);
    }

    // A lombada fecha o desenho e sustenta as folhas.
    canvas.drawLine(
      Offset(center.dx, center.dy - halfH * 0.86),
      Offset(center.dx, center.dy + halfH),
      stroke,
    );
  }

  /// Uma folha, presa na lombada e curvada na borda externa.
  ///
  /// [spread] é a fração da largura já aberta: em `0` a folha colapsa sobre a
  /// lombada, que é o livro fechado.
  Path _sheet(Offset c, double halfW, double halfH, double side, double spread) {
    final double w = halfW * spread;

    return Path()
      ..moveTo(c.dx, c.dy - halfH * 0.86)
      ..quadraticBezierTo(
        c.dx + side * w * 0.45,
        c.dy - halfH * 1.02,
        c.dx + side * w,
        c.dy - halfH * 0.42,
      )
      ..lineTo(c.dx + side * w, c.dy + halfH * 0.72)
      ..quadraticBezierTo(
        c.dx + side * w * 0.45,
        c.dy + halfH * 1.04,
        c.dx,
        c.dy + halfH,
      )
      ..close();
  }

  /// Duas linhas de texto insinuadas na folha, entrando junto com a abertura.
  void _lines(
    Canvas canvas,
    Size size,
    Offset c,
    double halfW,
    double halfH,
    double side,
  ) {
    if (open < 0.55) return;

    final Paint hair = Paint()
      ..color = ink.withValues(alpha: (open - 0.55) / 0.45 * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    for (final double at in <double>[-0.22, 0.12]) {
      canvas.drawLine(
        Offset(c.dx + side * halfW * open * 0.26, c.dy + halfH * at),
        Offset(c.dx + side * halfW * open * 0.74, c.dy + halfH * at * 0.86),
        hair,
      );
    }
  }

  @override
  bool shouldRepaint(_BookPainter old) =>
      old.open != open || old.turn != turn || old.ink != ink || old.page != page;
}
