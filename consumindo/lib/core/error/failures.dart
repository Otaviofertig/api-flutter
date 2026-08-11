import 'exceptions.dart';

/// Erros de **domínio**: é o que a camada de apresentação conhece.
///
/// [message] já vem pronta para exibição ao usuário.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Failure && other.runtimeType == runtimeType && other.message == message);

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';

  /// Traduz uma exceção de infraestrutura no `Failure` equivalente.
  static Failure fromException(Object error) {
    return switch (error) {
      AuthException e => AuthFailure(e.message, code: e.code),
      ServerException e => ServerFailure(e.message, statusCode: e.statusCode),
      NetworkException e => NetworkFailure(e.message),
      TimeoutException e => TimeoutFailure(e.message),
      ParseException e => ParseFailure(e.message),
      CacheException e => CacheFailure(e.message),
      _ => const UnexpectedFailure(),
    };
  }
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'A requisição demorou demais para responder.']);
}

final class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Não foi possível ler os dados recebidos.']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Falha ao acessar a sua estante local.']);
}

/// Falha de autenticação, já traduzida para o usuário.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code});

  /// Código original do provedor (ex.: `wrong-password`), para log.
  final String? code;
}

/// Entrada do usuário rejeitada por uma regra de domínio.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Algo deu errado. Tente novamente.']);
}
