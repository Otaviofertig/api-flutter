import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';
import 'auth_remote_datasource.dart';

/// Implementação de [IAuthRemoteDataSource] sobre o Firebase Authentication.
///
/// Responsabilidades: falar com o SDK, converter `User` em [AppUser] e
/// traduzir `FirebaseAuthException` em [AuthException] com mensagem em
/// português. Nenhuma decisão de UI acontece aqui.
final class FirebaseAuthDataSource implements IAuthRemoteDataSource {
  FirebaseAuthDataSource(this._auth);

  final fb.FirebaseAuth _auth;

  @override
  Stream<AppUser?> get authState =>
      _auth.authStateChanges().map(AppUserModel.fromNullable);

  @override
  AppUser? get currentUser => AppUserModel.fromNullable(_auth.currentUser);

  @override
  Future<AppUser> signInWithEmail(EmailCredentials credentials) {
    return _guard(() async {
      final fb.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: credentials.normalizedEmail,
        password: credentials.password,
      );
      return _requireUser(result);
    });
  }

  @override
  Future<AppUser> signUpWithEmail(EmailCredentials credentials) {
    return _guard(() async {
      final fb.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: credentials.normalizedEmail,
        password: credentials.password,
      );

      final fb.User user = _rawUser(result);
      final String? name = credentials.displayName?.trim();

      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
        // `updateDisplayName` não atualiza a instância em memória.
        await user.reload();
      }

      return AppUserModel.fromFirebase(_auth.currentUser ?? user);
    });
  }

  @override
  Future<AppUser> signInWithGoogle() {
    return _guard(() async {
      final fb.GoogleAuthProvider provider = fb.GoogleAuthProvider()
        ..addScope('email')
        // Força a escolha da conta em vez de reusar a última silenciosamente.
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});

      // O fluxo nativo (signInWithProvider) evita depender do pacote
      // google_sign_in; na web o Firebase exige popup.
      final fb.UserCredential result = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);

      return _requireUser(result);
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim().toLowerCase()));
  }

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  // --- Infra -----------------------------------------------------------------

  AppUser _requireUser(fb.UserCredential credential) =>
      AppUserModel.fromFirebase(_rawUser(credential));

  fb.User _rawUser(fb.UserCredential credential) {
    final fb.User? user = credential.user;
    if (user == null) {
      throw const AuthException('Não foi possível concluir o login.', code: 'null-user');
    }
    return user;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), code: e.code);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Não foi possível concluir a operação. Tente novamente.');
    }
  }

  /// Traduz os códigos do Firebase para mensagens que o usuário entende.
  ///
  /// Login e senha errados são propositalmente indistinguíveis (o Firebase
  /// moderno responde `invalid-credential` para ambos), o que evita revelar
  /// quais e-mails têm conta.
  String _messageFor(fb.FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'E-mail ou senha incorretos.',
      'invalid-email' => 'E-mail inválido.',
      'user-disabled' => 'Esta conta foi desativada.',
      'email-already-in-use' => 'Já existe uma conta com este e-mail.',
      'weak-password' => 'Escolha uma senha mais forte.',
      'operation-not-allowed' =>
        'Este método de login não está habilitado no projeto Firebase.',
      'too-many-requests' => 'Muitas tentativas. Aguarde alguns minutos.',
      'network-request-failed' => 'Sem conexão com a internet.',
      'popup-closed-by-user' ||
      'canceled' ||
      'web-context-canceled' =>
        'Login cancelado.',
      'account-exists-with-different-credential' =>
        'Este e-mail já está vinculado a outro método de login.',
      _ => error.message ?? 'Não foi possível concluir a operação.',
    };
  }
}
