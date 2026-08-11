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
  });

  const FirebaseEnv.empty()
      : apiKey = null,
        appId = null,
        messagingSenderId = null,
        projectId = null,
        authDomain = null,
        storageBucket = null;

  final String? apiKey;
  final String? appId;
  final String? messagingSenderId;
  final String? projectId;
  final String? authDomain;
  final String? storageBucket;

  /// Só há como inicializar o Firebase com estes quatro campos presentes.
  bool get isConfigured =>
      _filled(apiKey) && _filled(appId) && _filled(messagingSenderId) && _filled(projectId);

  /// Campos obrigatórios que faltaram — usado na mensagem de diagnóstico.
  List<String> get missingKeys => <String>[
        if (!_filled(apiKey)) 'FIREBASE_API_KEY',
        if (!_filled(appId)) 'FIREBASE_APP_ID',
        if (!_filled(messagingSenderId)) 'FIREBASE_MESSAGING_SENDER_ID',
        if (!_filled(projectId)) 'FIREBASE_PROJECT_ID',
      ];

  static bool _filled(String? value) => value != null && value.trim().isNotEmpty;
}
