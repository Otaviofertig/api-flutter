import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libria/features/auth/presentation/widgets/animated_brand_mark.dart';

/// Envolve a marca num app mínimo, com `disableAnimations` sob controle.
Widget _host({required bool reduceMotion}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const MaterialApp(
      home: Scaffold(body: Center(child: AnimatedBrandMark())),
    ),
  );
}

void main() {
  group('AnimatedBrandMark', () {
    testWidgets('atravessa a animação inteira sem exceção', (WidgetTester tester) async {
      await tester.pumpWidget(_host(reduceMotion: false));

      // Passo curto o bastante para cair dentro de cada Interval — inclusive
      // no meio da virada de página, onde a folha fica de perfil e a largura
      // passa por zero.
      for (int i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }

      expect(find.text('Libria'), findsOneWidget);
      expect(find.text('Seu guia literário'), findsOneWidget);
    });

    testWidgets('com reduzir movimento, assenta e para de animar',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(reduceMotion: true));

      // pumpAndSettle só retorna se não houver frame agendado: é a prova de
      // que o respiro contínuo não foi iniciado. Com a animação ligada, esta
      // mesma chamada estouraria o timeout.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Libria'), findsOneWidget);
    });

    testWidgets('sai de cena sem deixar ticker vivo', (WidgetTester tester) async {
      await tester.pumpWidget(_host(reduceMotion: false));
      await tester.pump(const Duration(milliseconds: 300));

      // Trocar a árvore força o dispose; um controller não descartado
      // derruba o teste aqui.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      expect(tester.takeException(), isNull);
    });
  });
}
