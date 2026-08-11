import 'package:consumindo/core/error/failures.dart';
import 'package:consumindo/core/error/result.dart';
import 'package:consumindo/features/auth/domain/entities/app_user.dart';
import 'package:consumindo/features/auth/domain/repositories/auth_repository.dart';
import 'package:consumindo/features/auth/domain/usecases/credential_validator.dart';
import 'package:consumindo/features/auth/domain/usecases/send_password_reset.dart';
import 'package:consumindo/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:consumindo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:consumindo/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:consumindo/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const AppUser _user = AppUser(id: 'uid-1', email: 'leitor@libria.app', displayName: 'Otávio');

class _FakeSignIn implements SignInWithEmail {
  _FakeSignIn(this.result);

  Result<AppUser> result;
  EmailCredentials? received;

  @override
  Future<Result<AppUser>> call(EmailCredentials params) async {
    received = params;
    return result;
  }
}

class _FakeSignUp implements SignUpWithEmail {
  _FakeSignUp(this.result);

  Result<AppUser> result;
  EmailCredentials? received;

  @override
  Future<Result<AppUser>> call(EmailCredentials params) async {
    received = params;
    return result;
  }
}

class _FakeGoogle implements SignInWithGoogle {
  _FakeGoogle(this.result);

  Result<AppUser> result;
  int calls = 0;

  @override
  Future<Result<AppUser>> call() async {
    calls++;
    return result;
  }
}

class _FakeReset implements SendPasswordReset {
  _FakeReset(this.result);

  Result<void> result;
  String? received;

  @override
  Future<Result<void>> call(String params) async {
    received = params;
    return result;
  }
}

void main() {
  group('CredentialValidator', () {
    test('rejeita e-mail malformado e senha curta', () {
      expect(CredentialValidator.emailError('sem-arroba'), isNotNull);
      expect(CredentialValidator.emailError('leitor@libria.app'), isNull);
      expect(CredentialValidator.passwordError('123'), isNotNull);
      expect(CredentialValidator.passwordError('123456'), isNull);
    });
  });

  group('LoginController', () {
    late _FakeSignIn signIn;
    late _FakeSignUp signUp;
    late _FakeGoogle google;
    late _FakeReset reset;
    late LoginController controller;

    setUp(() {
      signIn = _FakeSignIn(const Ok<AppUser>(_user));
      signUp = _FakeSignUp(const Ok<AppUser>(_user));
      google = _FakeGoogle(const Ok<AppUser>(_user));
      reset = _FakeReset(const Ok<void>(null));
      controller = LoginController(signIn, signUp, google, reset);
    });

    tearDown(() => controller.dispose());

    test('login bem-sucedido devolve o usuário e não deixa erro', () async {
      controller.onEmailChanged('leitor@libria.app');
      controller.onPasswordChanged('segredo123');

      final AppUser? user = await controller.submit();

      expect(user, _user);
      expect(controller.errorMessage, isNull);
      expect(controller.isSubmitting, isFalse);
      expect(signIn.received?.normalizedEmail, 'leitor@libria.app');
    });

    test('credenciais inválidas viram mensagem na tela', () async {
      signIn.result = const Err<AppUser>(AuthFailure('E-mail ou senha incorretos.'));
      controller.onEmailChanged('leitor@libria.app');
      controller.onPasswordChanged('senha-errada');

      final AppUser? user = await controller.submit();

      expect(user, isNull);
      expect(controller.errorMessage, 'E-mail ou senha incorretos.');
    });

    test('digitar depois do erro limpa a mensagem', () async {
      signIn.result = const Err<AppUser>(AuthFailure('E-mail ou senha incorretos.'));
      controller.onEmailChanged('leitor@libria.app');
      controller.onPasswordChanged('errada');
      await controller.submit();

      controller.onPasswordChanged('outra-tentativa');

      expect(controller.errorMessage, isNull);
    });

    test('no modo cadastro chama o caso de uso de cadastro com o nome', () async {
      controller.toggleMode();
      controller.onNameChanged('Otávio');
      controller.onEmailChanged('novo@libria.app');
      controller.onPasswordChanged('segredo123');

      await controller.submit();

      expect(controller.mode, AuthMode.signUp);
      expect(signUp.received?.displayName, 'Otávio');
      expect(signIn.received, isNull);
    });

    test('login com Google delega ao caso de uso', () async {
      final AppUser? user = await controller.signInWithGoogle();

      expect(google.calls, 1);
      expect(user, _user);
    });

    test('redefinição de senha valida o e-mail antes de chamar o provedor',
        () async {
      reset.result = const Err<void>(ValidationFailure('E-mail inválido.'));
      controller.onEmailChanged('quebrado');

      final String message = await controller.sendPasswordReset();

      expect(message, 'E-mail inválido.');
      expect(controller.errorMessage, 'E-mail inválido.');
    });
  });
}
