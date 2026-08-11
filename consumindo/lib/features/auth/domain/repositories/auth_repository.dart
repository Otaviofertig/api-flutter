import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

/// Credenciais de e-mail e senha.
final class EmailCredentials {
  const EmailCredentials({required this.email, required this.password, this.displayName});

  final String email;
  final String password;

  /// Usado apenas no cadastro.
  final String? displayName;

  String get normalizedEmail => email.trim().toLowerCase();
}

/// Contrato de autenticação. A camada de apresentação depende só disto —
/// o Firebase é um detalhe substituível na camada de data.
abstract interface class IAuthRepository {
  /// Emite o usuário a cada mudança de sessão (`null` = deslogado).
  Stream<AppUser?> get authState;

  /// Usuário da sessão corrente, se houver.
  AppUser? get currentUser;

  Future<Result<AppUser>> signInWithEmail(EmailCredentials credentials);

  Future<Result<AppUser>> signUpWithEmail(EmailCredentials credentials);

  Future<Result<AppUser>> signInWithGoogle();

  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<void>> signOut();
}
