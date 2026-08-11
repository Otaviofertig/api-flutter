import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import 'credential_validator.dart';

/// Login com e-mail e senha.
///
/// A validação de formato mora aqui, não na tela: qualquer entrada do app
/// (login, deep link, teste) passa pela mesma regra.
class SignInWithEmail implements UseCase<AppUser, EmailCredentials> {
  const SignInWithEmail(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AppUser>> call(EmailCredentials params) async {
    final ValidationFailure? invalid = CredentialValidator.validateSignIn(params);
    if (invalid != null) return Err<AppUser>(invalid);

    return _repository.signInWithEmail(params);
  }
}
