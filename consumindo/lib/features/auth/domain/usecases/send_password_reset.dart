import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';
import 'credential_validator.dart';

/// Envia o e-mail de redefinição de senha.
class SendPasswordReset implements UseCase<void, String> {
  const SendPasswordReset(this._repository);

  final IAuthRepository _repository;

  @override
  Future<Result<void>> call(String params) async {
    final String? error = CredentialValidator.emailError(params);
    if (error != null) return Err<void>(ValidationFailure(error));

    return _repository.sendPasswordReset(params.trim());
  }
}
