import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Login com a conta Google.
class SignInWithGoogle implements NoParamsUseCase<AppUser> {
  const SignInWithGoogle(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AppUser>> call() => _repository.signInWithGoogle();
}
