import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libria/core/theme/theme_controller.dart';
import 'package:libria/core/theme/theme_preference.dart';

/// Preferência em memória, com contagem de escritas.
class _FakePreference implements IThemePreference {
  _FakePreference([this._stored = ThemeMode.system]);

  ThemeMode _stored;
  int writes = 0;
  bool failOnWrite = false;

  @override
  ThemeMode read() => _stored;

  @override
  Future<void> write(ThemeMode mode) async {
    writes++;
    if (failOnWrite) throw Exception('disco cheio');
    _stored = mode;
  }
}

void main() {
  group('ThemeController', () {
    test('abre no que estava guardado, sem passar por system', () {
      final ThemeController controller = ThemeController(_FakePreference(ThemeMode.dark));

      expect(controller.mode, ThemeMode.dark);
      expect(controller.followsSystem, isFalse);
    });

    test('trocar de modo notifica e persiste', () async {
      final _FakePreference prefs = _FakePreference();
      final ThemeController controller = ThemeController(prefs);
      int notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setMode(ThemeMode.dark);

      expect(controller.mode, ThemeMode.dark);
      expect(notifications, 1);
      expect(prefs.writes, 1);
      expect(prefs.read(), ThemeMode.dark);
    });

    test('escolher o modo que já vale não escreve nem notifica', () async {
      final _FakePreference prefs = _FakePreference(ThemeMode.light);
      final ThemeController controller = ThemeController(prefs);
      int notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setMode(ThemeMode.light);

      expect(notifications, isZero);
      expect(prefs.writes, isZero);
    });

    testWidgets('em system, isDark segue o brilho da plataforma',
        (WidgetTester tester) async {
      final ThemeController controller = ThemeController(_FakePreference());
      late BuildContext ctx;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: Builder(
            builder: (BuildContext context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(controller.followsSystem, isTrue);
      expect(controller.isDark(ctx), isTrue);

      // Escolha explícita ganha do aparelho.
      await controller.setMode(ThemeMode.light);
      expect(controller.isDark(ctx), isFalse);
    });

    testWidgets('toggle sai de system para o oposto do que está na tela',
        (WidgetTester tester) async {
      final ThemeController controller = ThemeController(_FakePreference());
      late BuildContext ctx;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: Builder(
            builder: (BuildContext context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await controller.toggle(ctx);

      expect(controller.mode, ThemeMode.light);
      expect(controller.followsSystem, isFalse);
    });

    test('falha ao gravar não desfaz a troca já pintada na tela', () async {
      final _FakePreference prefs = _FakePreference()..failOnWrite = true;
      final ThemeController controller = ThemeController(prefs);

      await expectLater(controller.setMode(ThemeMode.dark), throwsException);

      // O pior caso é a escolha não sobreviver ao próximo boot — nunca a tela
      // voltar sozinha para o tema anterior debaixo de quem acabou de tocar.
      expect(controller.mode, ThemeMode.dark);
    });
  });
}
