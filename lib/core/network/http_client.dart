/// Contrato de cliente HTTP (Dependency Inversion).
///
/// A camada de data depende desta abstração, nunca do package `http`.
/// Trocar por Dio/Chopper ou mockar em testes não afeta nenhuma outra camada.
abstract interface class IHttpClient {
  /// Executa um GET e devolve o corpo já decodificado como JSON.
  ///
  /// Lança [ServerException], [NetworkException], [TimeoutException] ou
  /// [ParseException] (ver `core/error/exceptions.dart`).
  Future<dynamic> getJson(Uri url, {Map<String, String>? headers});

  /// Libera recursos (conexões keep-alive).
  void dispose();
}
