import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementação de [IAuthRepository]: converte exceções em `Failure`.
class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._remote);

  final IAuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> get authState => _remote.authState;

  @override
  AppUser? get currentUser => _remote.currentUser;

  @override
  Future<Result<AppUser>> signInWithEmail(EmailCredentials credentials) =>
      _guard(() => _remote.signInWithEmail(credentials));

  @override
  Future<Result<AppUser>> signUpWithEmail(EmailCredentials credentials) =>
      _guard(() => _remote.signUpWithEmail(credentials));

  @override
  Future<Result<AppUser>> signInWithGoogle() => _guard(_remote.signInWithGoogle);

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      _guard(() => _remote.sendPasswordReset(email));

  @override
  Future<Result<void>> signOut() => _guard(_remote.signOut);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok<T>(await action());
    } on AppException catch (e) {
      return Err<T>(Failure.fromException(e));
    } catch (_) {
      return Err<T>(const UnexpectedFailure());
    }
  }
}
