import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/firebase_env.dart';
import '../../../../core/config/firebase_platform.dart';

/// Inicializa o Firebase a partir das credenciais do `.env`.
///
/// Substitui o `firebase_options.dart` gerado pelo `flutterfire configure` —
/// que versionaria as chaves do projeto no repositório.
///
/// Se as credenciais não estiverem no `.env`, o app sobe sem autenticação em
/// vez de quebrar: o acervo da Open Library é público e continua navegável.
abstract final class FirebaseBootstrap {
  /// `true` quando o Firebase ficou pronto para uso.
  static Future<bool> initialize(FirebaseEnv env) async {
    if (!env.isConfigured) {
      debugPrint(
        '[Libria] Firebase desativado: faltam ${env.missingKeys.join(", ")} no .env. '
        '${_platformHint(env)}'
        'O app segue funcionando sem login.',
      );
      return false;
    }

    try {
      await Firebase.initializeApp(options: _optionsFrom(env));
      return true;
    } catch (error) {
      debugPrint('[Libria] Falha ao inicializar o Firebase: $error');
      return false;
    }
  }

  /// Lembra que existe a variante com prefixo, que tem precedência sobre a
  /// genérica — sem ela o diagnóstico manda preencher a chave errada em quem
  /// mantém web e Android no mesmo `.env`.
  static String _platformHint(FirebaseEnv env) {
    final FirebasePlatform? platform = env.platform;
    if (platform == null) return '';
    return 'Nesta plataforma as variantes FIREBASE_${platform.envPrefix}_* '
        'também valem, e vêm na frente. ';
  }

  static FirebaseOptions _optionsFrom(FirebaseEnv env) {
    return FirebaseOptions(
      apiKey: env.apiKey!,
      appId: env.appId!,
      messagingSenderId: env.messagingSenderId!,
      projectId: env.projectId!,
      authDomain: env.authDomain,
      storageBucket: env.storageBucket,
    );
  }
}
