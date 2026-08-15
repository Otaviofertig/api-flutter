import 'package:flutter/material.dart';

import 'theme_preference.dart';

/// Dono da escolha de tema do app.
///
/// Vive acima do `MaterialApp` (a raiz escuta e repassa para `themeMode`), por
/// isso mora em `core` e não num feature: tema não pertence a busca nem a
/// login, pertence ao app inteiro.
class ThemeController extends ChangeNotifier {
  ThemeController(this._preference) : _mode = _preference.read();

  final IThemePreference _preference;

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// `true` quando o app segue o aparelho em vez de uma escolha explícita.
  bool get followsSystem => _mode == ThemeMode.system;

  /// Qual tema está valendo agora, já resolvendo `system` contra o aparelho.
  ///
  /// O botão precisa disso para desenhar o ícone certo: em `ThemeMode.system`
  /// o modo por si só não diz se a tela está clara ou escura.
  bool isDark(BuildContext context) {
    return switch (_mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;

    // Pinta primeiro, grava depois: a troca de tema é instantânea na tela e
    // não fica esperando o disco. Se a escrita falhar, o pior caso é a
    // escolha não sobreviver ao próximo boot.
    _mode = mode;
    notifyListeners();

    await _preference.write(mode);
  }

  /// Alterna entre claro e escuro a partir do que está na tela.
  ///
  /// Sai de `system` na primeira vez que alguém toca: quem alternou quis
  /// escolher, e devolver o controle ao aparelho tem item próprio no menu.
  Future<void> toggle(BuildContext context) {
    return setMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }
}
