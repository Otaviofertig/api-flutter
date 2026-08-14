import 'package:flutter_test/flutter_test.dart';
import 'package:libria/core/config/firebase_env.dart';
import 'package:libria/core/config/firebase_platform.dart';

/// Leitor com a mesma semântica do `AppConfig._optional`: chave ausente e
/// valor em branco são a mesma coisa — `null`.
String? Function(String) readerOf(Map<String, String> env) {
  return (String key) {
    final String? value = env[key];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  };
}

void main() {
  group('FirebaseEnv.forPlatform', () {
    // O mesmo `.env` que um time com web e Android manteria.
    final Map<String, String> multiPlataforma = <String, String>{
      'FIREBASE_PROJECT_ID': 'libria-prod',
      'FIREBASE_MESSAGING_SENDER_ID': '1234567890',
      'FIREBASE_WEB_API_KEY': 'chave-web',
      'FIREBASE_WEB_APP_ID': '1:1234567890:web:abc',
      'FIREBASE_WEB_AUTH_DOMAIN': 'libria-prod.firebaseapp.com',
      'FIREBASE_ANDROID_API_KEY': 'chave-android',
      'FIREBASE_ANDROID_APP_ID': '1:1234567890:android:def',
    };

    test('a chave da plataforma vence a genérica', () {
      final FirebaseEnv env = FirebaseEnv.forPlatform(
        FirebasePlatform.web,
        readerOf(<String, String>{
          ...multiPlataforma,
          'FIREBASE_APP_ID': '1:1234567890:generico:xyz',
        }),
      );

      expect(env.appId, '1:1234567890:web:abc');
    });

    test('web e android leem do mesmo .env sem se misturar', () {
      final FirebaseEnv web =
          FirebaseEnv.forPlatform(FirebasePlatform.web, readerOf(multiPlataforma));
      final FirebaseEnv android =
          FirebaseEnv.forPlatform(FirebasePlatform.android, readerOf(multiPlataforma));

      expect(web.appId, '1:1234567890:web:abc');
      expect(web.apiKey, 'chave-web');
      expect(android.appId, '1:1234567890:android:def');
      expect(android.apiKey, 'chave-android');

      // O que é do projeto, e não da plataforma, é compartilhado.
      expect(web.projectId, 'libria-prod');
      expect(android.projectId, 'libria-prod');
      expect(web.messagingSenderId, android.messagingSenderId);

      expect(web.isConfigured, isTrue);
      expect(android.isConfigured, isTrue);
    });

    test('sem variante da plataforma, a genérica ainda vale', () {
      // O formato antigo, de antes das chaves por plataforma: precisa
      // continuar subindo sem editar o .env.
      final FirebaseEnv env = FirebaseEnv.forPlatform(
        FirebasePlatform.android,
        readerOf(<String, String>{
          'FIREBASE_API_KEY': 'chave-unica',
          'FIREBASE_APP_ID': '1:1234567890:android:def',
          'FIREBASE_MESSAGING_SENDER_ID': '1234567890',
          'FIREBASE_PROJECT_ID': 'libria-prod',
        }),
      );

      expect(env.isConfigured, isTrue);
      expect(env.apiKey, 'chave-unica');
      expect(env.missingKeys, isEmpty);
    });

    test('variante em branco não sobrescreve a genérica preenchida', () {
      final FirebaseEnv env = FirebaseEnv.forPlatform(
        FirebasePlatform.ios,
        readerOf(<String, String>{
          'FIREBASE_IOS_APP_ID': '   ',
          'FIREBASE_APP_ID': '1:1234567890:generico:xyz',
        }),
      );

      expect(env.appId, '1:1234567890:generico:xyz');
    });

    test('sem plataforma, as variantes com prefixo são ignoradas', () {
      // É o caso do Linux, onde o Firebase não tem suporte.
      final FirebaseEnv env = FirebaseEnv.forPlatform(null, readerOf(multiPlataforma));

      expect(env.appId, isNull);
      expect(env.apiKey, isNull);
      expect(env.isConfigured, isFalse);
      expect(env.platform, isNull);
    });

    test('o .env de uma plataforma só não configura a outra', () {
      // Preencher com as chaves da web e rodar no Android era exatamente o
      // bug: o initializeApp recebia um appId que não era o do Android.
      // Agora falta o obrigatório, e o app cai no modo sem login.
      final FirebaseEnv android = FirebaseEnv.forPlatform(
        FirebasePlatform.android,
        readerOf(<String, String>{
          'FIREBASE_WEB_API_KEY': 'chave-web',
          'FIREBASE_WEB_APP_ID': '1:1234567890:web:abc',
          'FIREBASE_MESSAGING_SENDER_ID': '1234567890',
          'FIREBASE_PROJECT_ID': 'libria-prod',
        }),
      );

      expect(android.isConfigured, isFalse);
      expect(android.missingKeys, <String>['FIREBASE_API_KEY', 'FIREBASE_APP_ID']);
      expect(android.platform, FirebasePlatform.android);
    });
  });
}
