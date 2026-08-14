import 'package:flutter/foundation.dart';

/// Plataforma-alvo das credenciais do Firebase.
///
/// O console emite um `appId` diferente para **cada plataforma registrada** —
/// e, em geral, uma `apiKey` diferente também. O prefixo do nome da variável é
/// o que permite a um único `.env` servir web e Android ao mesmo tempo, em vez
/// de uma plataforma por arquivo.
enum FirebasePlatform {
  web('WEB'),
  android('ANDROID'),
  ios('IOS'),
  macos('MACOS'),
  windows('WINDOWS');

  const FirebasePlatform(this.envPrefix);

  /// Trecho que entra entre `FIREBASE_` e o nome da chave — por exemplo,
  /// `FIREBASE_WEB_APP_ID`.
  final String envPrefix;

  /// A plataforma em que o app está rodando agora.
  ///
  /// `null` onde o Firebase não tem suporte (Linux, Fuchsia): ali só valem as
  /// chaves genéricas, e a inicialização vai falhar de qualquer forma — o
  /// bootstrap trata isso caindo para o modo sem login.
  ///
  /// O `kIsWeb` vem antes do `defaultTargetPlatform` de propósito: na web o
  /// `defaultTargetPlatform` responde o sistema de quem navega (android num
  /// celular, macos num Mac), o que escolheria o `appId` errado.
  static FirebasePlatform? get current {
    if (kIsWeb) return FirebasePlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => FirebasePlatform.android,
      TargetPlatform.iOS => FirebasePlatform.ios,
      TargetPlatform.macOS => FirebasePlatform.macos,
      TargetPlatform.windows => FirebasePlatform.windows,
      TargetPlatform.linux || TargetPlatform.fuchsia => null,
    };
  }
}
