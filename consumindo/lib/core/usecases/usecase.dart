import '../error/result.dart';

/// Contrato de um caso de uso assíncrono.
///
/// Uma única responsabilidade por classe (SRP) e um único ponto de entrada
/// (`call`), o que permite injetar/mockar cada regra isoladamente.
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Caso de uso sem parâmetros.
abstract interface class NoParamsUseCase<T> {
  Future<Result<T>> call();
}

/// Marcador para casos de uso que não recebem argumentos.
final class NoParams {
  const NoParams();
}
