import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/credential_validator.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_up_with_email.dart';

/// Modo do formulário: entrar em uma conta existente ou criar uma nova.
enum AuthMode {
  signIn,
  signUp;

  bool get isSignUp => this == AuthMode.signUp;

  String get title => isSignUp ? 'Criar conta' : 'Entrar';

  String get submitLabel => isSignUp ? 'Criar minha conta' : 'Entrar';

  String get switchPrompt =>
      isSignUp ? 'Já tem conta? Entrar' : 'Ainda não tem conta? Criar uma';

  AuthMode get toggled => isSignUp ? AuthMode.signIn : AuthMode.signUp;
}

/// Controller do formulário de login/cadastro.
///
/// Guarda os valores dos campos, o modo atual e o erro da última tentativa.
/// A validação vem do domínio ([CredentialValidator]), não é reescrita aqui.
class LoginController extends ChangeNotifier {
  LoginController(
    this._signIn,
    this._signUp,
    this._signInWithGoogle,
    this._sendPasswordReset,
  );

  final SignInWithEmail _signIn;
  final SignUpWithEmail _signUp;
  final SignInWithGoogle _signInWithGoogle;
  final SendPasswordReset _sendPasswordReset;

  AuthMode _mode = AuthMode.signIn;
  AuthMode get mode => _mode;

  String _name = '';
  String _email = '';
  String _password = '';

  String get email => _email;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  void onNameChanged(String value) => _name = value;

  void onEmailChanged(String value) {
    _email = value;
    _clearError();
  }

  void onPasswordChanged(String value) {
    _password = value;
    _clearError();
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    _notify();
  }

  void toggleMode() {
    _mode = _mode.toggled;
    _errorMessage = null;
    _notify();
  }

  // Validadores expostos para o `Form` da tela — mesma regra do domínio.
  String? validateName(String? value) =>
      _mode.isSignUp ? CredentialValidator.nameError(value ?? '') : null;

  String? validateEmail(String? value) => CredentialValidator.emailError(value ?? '');

  String? validatePassword(String? value) =>
      CredentialValidator.passwordError(value ?? '');

  /// Faz login ou cadastro conforme o [mode]. Retorna o usuário em caso de
  /// sucesso; em caso de falha, a mensagem fica em [errorMessage].
  Future<AppUser?> submit() async {
    final EmailCredentials credentials = EmailCredentials(
      email: _email,
      password: _password,
      displayName: _mode.isSignUp ? _name : null,
    );

    return _run(() => _mode.isSignUp ? _signUp(credentials) : _signIn(credentials));
  }

  Future<AppUser?> signInWithGoogle() => _run(_signInWithGoogle.call);

  /// Envia o e-mail de redefinição e devolve a mensagem a exibir.
  Future<String> sendPasswordReset() async {
    if (_isSubmitting) return '';

    _setSubmitting(true);
    final Result<void> result = await _sendPasswordReset(_email);
    _setSubmitting(false);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _notify();
        return failure.message;
      },
      (_) => 'Enviamos um link de redefinição para ${_email.trim()}.',
    );
  }

  Future<AppUser?> _run(Future<Result<AppUser>> Function() action) async {
    if (_isSubmitting) return null;

    _errorMessage = null;
    _setSubmitting(true);

    final Result<AppUser> result = await action();

    _setSubmitting(false);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _notify();
        return null;
      },
      (AppUser user) => user,
    );
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    _notify();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
