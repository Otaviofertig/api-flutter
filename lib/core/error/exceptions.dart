/// Exceções lançadas pela camada de **data** (datasources).
///
/// Nunca cruzam a fronteira do repositório: são convertidas em `Failure`.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// Erro retornado pelo servidor (4xx / 5xx).
final class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

/// Sem conectividade ou host inacessível.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'Sem conexão com a internet.']);
}

/// A requisição excedeu o tempo limite.
final class TimeoutException extends AppException {
  const TimeoutException([super.message = 'A requisição demorou demais para responder.']);
}

/// Payload em formato inesperado.
final class ParseException extends AppException {
  const ParseException([super.message = 'Resposta em formato inválido.']);
}

/// Falha ao ler/gravar no armazenamento local.
final class CacheException extends AppException {
  const CacheException([super.message = 'Falha ao acessar os dados locais.']);
}

/// Falha de autenticação. [code] guarda o código original do provedor
/// (ex.: `wrong-password`), útil para log e telemetria.
final class AuthException extends AppException {
  const AuthException(super.message, {this.code});

  final String? code;
}
