import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/app_user.dart';

/// Converte o `User` do Firebase na entidade de domínio [AppUser].
///
/// É o único ponto do app que conhece o formato do SDK.
final class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    super.email,
    super.displayName,
    super.photoUrl,
    super.isEmailVerified,
    super.providers,
  });

  factory AppUserModel.fromFirebase(fb.User user) {
    return AppUserModel(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      providers: user.providerData
          .map((fb.UserInfo info) => info.providerId)
          .toList(growable: false),
    );
  }

  /// `null` quando não há sessão — facilita mapear `authStateChanges()`.
  static AppUserModel? fromNullable(fb.User? user) =>
      user == null ? null : AppUserModel.fromFirebase(user);
}
