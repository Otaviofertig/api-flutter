import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_remote_datasource.dart';

/// Fonte de autenticação usada quando o Firebase não está configurado.
///
/// Null Object: mantém o contrato válido (a injeção de dependência sempre
/// resolve) e falha com uma mensagem clara se alguém tentar autenticar.
/// Nenhuma tela precisa checar "o Firebase existe?" antes de chamar.
final class DisabledAuthDataSource implements IAuthRemoteDataSource {
  const DisabledAuthDataSource();

  static const AuthException _disabled = AuthException(
    'Login indisponível: o Firebase não está configurado neste ambiente.',
    code: 'auth-disabled',
  );

  @override
  Stream<AppUser?> get authState => Stream<AppUser?>.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> signInWithEmail(EmailCredentials credentials) => throw _disabled;

  @override
  Future<AppUser> signUpWithEmail(EmailCredentials credentials) => throw _disabled;

  @override
  Future<AppUser> signInWithGoogle() => throw _disabled;

  @override
  Future<void> sendPasswordReset(String email) => throw _disabled;

  @override
  Future<void> signOut() async {}
}
