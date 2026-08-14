import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Onde a escolha de tema fica guardada entre sessões.
///
/// Interface própria pelo mesmo motivo do resto do app: trocar
/// `shared_preferences` por outra coisa não deve tocar em quem lê o tema.
abstract interface class IThemePreference {
  /// Leitura **síncrona**, de propósito.
  ///
  /// O `SharedPreferences` já está carregado quando o app monta (o `main`
  /// resolve antes da DI), então dá para pintar o primeiro frame no tema certo.
  /// Um `Future` aqui custaria um flash de tema claro antes do escuro.
  ThemeMode read();

  Future<void> write(ThemeMode mode);
}

/// Implementação sobre `shared_preferences`, guardando o modo como string.
final class SharedPreferencesThemePreference implements IThemePreference {
  const SharedPreferencesThemePreference(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'libria.theme_mode.v1';

  @override
  ThemeMode read() {
    // Valor ausente ou irreconhecível cai em `system`: seguir o aparelho é o
    // padrão menos surpreendente para quem nunca escolheu nada.
    return switch (_prefs.getString(key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> write(ThemeMode mode) async {
    await _prefs.setString(key, mode.name);
  }
}
