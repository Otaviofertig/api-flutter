import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';
import 'credential_validator.dart';

/// Cadastro com e-mail, senha e nome de exibição.
class SignUpWithEmail implements UseCase<AppUser, EmailCredentials> {
  const SignUpWithEmail(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<AppUser>> call(EmailCredentials params) async {
    final ValidationFailure? invalid = CredentialValidator.validateSignUp(params);
    if (invalid != null) return Err<AppUser>(invalid);

    return _repository.signUpWithEmail(params);
  }
}
