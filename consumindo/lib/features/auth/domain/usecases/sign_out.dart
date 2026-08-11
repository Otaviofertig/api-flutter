import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Encerra a sessão atual.
class SignOut implements NoParamsUseCase<void> {
  const SignOut(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<void>> call() => _repository.signOut();
}
