import 'failures.dart';

/// `Either` minimalista: sucesso ([Ok]) ou falha ([Err]).
///
/// Evita uma dependência externa (dartz) e mantém o contrato dos repositórios
/// explícito — nada de `throw` atravessando as camadas.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) { Ok<T>(:final T value) => value, Err<T>() => null };
  Failure? get failureOrNull => switch (this) { Ok<T>() => null, Err<T>(:final Failure failure) => failure };

  /// Colapsa os dois ramos em um único valor.
  R fold<R>(R Function(Failure failure) onErr, R Function(T value) onOk) {
    return switch (this) {
      Ok<T>(:final T value) => onOk(value),
      Err<T>(:final Failure failure) => onErr(failure),
    };
  }

  /// Transforma o valor de sucesso, preservando a falha.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok<T>(:final T value) => Ok<R>(transform(value)),
      Err<T>(:final Failure failure) => Err<R>(failure),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
