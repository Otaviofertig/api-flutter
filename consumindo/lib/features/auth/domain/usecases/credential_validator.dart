import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Regras de validação de credenciais, compartilhadas pelos casos de uso.
///
/// Também expõe validadores por campo, para a tela dar feedback enquanto o
/// usuário digita sem duplicar a regra.
abstract final class CredentialValidator {
  static const int minPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// `null` quando o e-mail é válido; caso contrário, a mensagem de erro.
  static String? emailError(String email) {
    final String value = email.trim();
    if (value.isEmpty) return 'Informe seu e-mail.';
    if (!_emailPattern.hasMatch(value)) return 'E-mail inválido.';
    return null;
  }

  static String? passwordError(String password) {
    if (password.isEmpty) return 'Informe sua senha.';
    if (password.length < minPasswordLength) {
      return 'A senha precisa de ao menos $minPasswordLength caracteres.';
    }
    return null;
  }

  static String? nameError(String name) {
    if (name.trim().length < 2) return 'Informe seu nome.';
    return null;
  }

  static ValidationFailure? validateSignIn(EmailCredentials credentials) {
    final String? error =
        emailError(credentials.email) ?? passwordError(credentials.password);
    return error == null ? null : ValidationFailure(error);
  }

  static ValidationFailure? validateSignUp(EmailCredentials credentials) {
    final String? error = emailError(credentials.email) ??
        passwordError(credentials.password) ??
        nameError(credentials.displayName ?? '');
    return error == null ? null : ValidationFailure(error);
  }
}
