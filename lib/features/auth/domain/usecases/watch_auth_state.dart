import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Observa a sessão: emite o usuário atual ou `null` quando deslogado.
///
/// Não usa `Result` porque é um fluxo contínuo, e não uma operação que
/// falha uma vez — erros do provedor viram desconexão (`null`).
class WatchAuthState {
  const WatchAuthState(this._repository);

  final IAuthRepository _repository;

  Stream<AppUser?> call() => _repository.authState;

  AppUser? get current => _repository.currentUser;
}
