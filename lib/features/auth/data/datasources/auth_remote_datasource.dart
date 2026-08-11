import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Fonte de dados de autenticação. Lança `AuthException` em caso de erro.
///
/// Trocar o Firebase por outro provedor significa escrever outra
/// implementação desta interface — nada acima da camada de data muda.
abstract interface class IAuthRemoteDataSource {
  Stream<AppUser?> get authState;

  AppUser? get currentUser;

  Future<AppUser> signInWithEmail(EmailCredentials credentials);

  Future<AppUser> signUpWithEmail(EmailCredentials credentials);

  Future<AppUser> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
