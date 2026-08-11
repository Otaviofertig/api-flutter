import '../../../../core/session/session_scope.dart';
import '../../domain/repositories/auth_repository.dart';

/// Liga o escopo dos dados locais à sessão autenticada.
///
/// Lê a sessão a cada consulta em vez de guardar o uid: login e logout em
/// runtime passam a valer na hora, sem reconstruir a injeção de dependência.
final class AuthSessionScope implements ISessionScope {
  const AuthSessionScope(this._auth);

  final IAuthRepository _auth;

  @override
  String? get scopeId => _auth.currentUser?.id;
}
