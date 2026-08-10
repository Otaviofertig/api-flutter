import '../error/failures.dart';

/// Estados exaustivos de uma tela: `Idle`, `Loading`, `Empty`, `Success`, `Error`.
///
/// Sendo `sealed`, o `switch` na View é verificado pelo compilador — não existe
/// caminho de UI esquecido.
sealed class UiState<T> {
  const UiState();

  const factory UiState.idle() = IdleState<T>;
  const factory UiState.loading() = LoadingState<T>;
  const factory UiState.empty([String message]) = EmptyState<T>;
  const factory UiState.success(T data) = SuccessState<T>;
  const factory UiState.error(Failure failure) = ErrorState<T>;

  bool get isLoading => this is LoadingState<T>;
  T? get dataOrNull => this is SuccessState<T> ? (this as SuccessState<T>).data : null;
}

final class IdleState<T> extends UiState<T> {
  const IdleState();
}

final class LoadingState<T> extends UiState<T> {
  const LoadingState();
}

final class EmptyState<T> extends UiState<T> {
  const EmptyState([this.message = 'Nada por aqui ainda.']);

  final String message;
}

final class SuccessState<T> extends UiState<T> {
  const SuccessState(this.data);

  final T data;
}

final class ErrorState<T> extends UiState<T> {
  const ErrorState(this.failure);

  final Failure failure;
}
