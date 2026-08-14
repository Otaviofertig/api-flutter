import 'firebase_platform.dart';

/// Credenciais do projeto Firebase, lidas do `.env`.
///
/// Ficam em `core/config` como dados brutos — a conversão para
/// `FirebaseOptions` acontece na camada de data, para que o core não dependa
/// do SDK do Firebase.
///
/// Substituem o `firebase_options.dart` gerado pelo `flutterfire configure`,
/// que carregaria as chaves para dentro do repositório.
final class FirebaseEnv {
  const FirebaseEnv({
    this.apiKey,
    this.appId,
    this.messagingSenderId,
    this.projectId,
    this.authDomain,
    this.storageBucket,
    this.platform,
  });

  /// Monta as credenciais preferindo as chaves de [platform], com as genéricas
  /// como fallback: `FIREBASE_WEB_APP_ID` vence `FIREBASE_APP_ID`.
  ///
  /// A precedência nesta ordem é o que mantém um `.env` antigo — só com as
  /// chaves genéricas — funcionando sem edição, ao mesmo tempo em que permite
  /// declarar web e Android lado a lado no mesmo arquivo.
  ///
  /// Com [platform] nulo só as genéricas entram. [read] deve devolver `null`
  /// tanto para chave ausente quanto para valor vazio.
  factory FirebaseEnv.forPlatform(
    FirebasePlatform? platform,
    String? Function(String key) read,
  ) {
    String? pick(String name) {
      final String? specific =
          platform == null ? null : read('FIREBASE_${platform.envPrefix}_$name');
      return specific ?? read('FIREBASE_$name');
    }

    return FirebaseEnv(
      apiKey: pick('API_KEY'),
      appId: pick('APP_ID'),
      messagingSenderId: pick('MESSAGING_SENDER_ID'),
      projectId: pick('PROJECT_ID'),
      authDomain: pick('AUTH_DOMAIN'),
      storageBucket: pick('STORAGE_BUCKET'),
      platform: platform,
    );
  }

  const FirebaseEnv.empty()
      : apiKey = null,
        appId = null,
        messagingSenderId = null,
        projectId = null,
        authDomain = null,
        storageBucket = null,
        platform = null;

  final String? apiKey;
  final String? appId;
  final String? messagingSenderId;
  final String? projectId;
  final String? authDomain;
  final String? storageBucket;

  /// Plataforma cujas chaves foram consultadas; `null` quando apenas as
  /// genéricas estavam em jogo. Serve ao diagnóstico: dizer *quais* chaves
  /// faltaram sem dizer *para qual plataforma* manda procurar no lugar errado.
  final FirebasePlatform? platform;

  /// Só há como inicializar o Firebase com estes quatro campos presentes.
  bool get isConfigured =>
      _filled(apiKey) && _filled(appId) && _filled(messagingSenderId) && _filled(projectId);

  /// Campos obrigatórios que faltaram — usado na mensagem de diagnóstico.
  ///
  /// Reporta sempre o nome genérico: ele resolve em qualquer plataforma, e a
  /// variante com prefixo aparece à parte na mensagem do bootstrap.
  List<String> get missingKeys => <String>[
        if (!_filled(apiKey)) 'FIREBASE_API_KEY',
        if (!_filled(appId)) 'FIREBASE_APP_ID',
        if (!_filled(messagingSenderId)) 'FIREBASE_MESSAGING_SENDER_ID',
        if (!_filled(projectId)) 'FIREBASE_PROJECT_ID',
      ];

  static bool _filled(String? value) => value != null && value.trim().isNotEmpty;
}
