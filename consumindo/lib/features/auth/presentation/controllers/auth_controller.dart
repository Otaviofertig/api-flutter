import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/watch_auth_state.dart';

/// Sessão do usuário — vive enquanto o app estiver aberto.
///
/// É a única fonte de verdade sobre "quem está logado": telas apenas observam.
class AuthController extends ChangeNotifier {
  AuthController(this._watchAuthState, this._signOut) {
    _user = _watchAuthState.current;
    _subscription = _watchAuthState().listen(_onUserChanged);
  }

  final WatchAuthState _watchAuthState;
  final SignOut _signOut;

  StreamSubscription<AppUser?>? _subscription;

  AppUser? _user;
  AppUser? get user => _user;

  bool get isAuthenticated => _user != null;

  /// `false` até o primeiro evento do provedor: evita piscar a tela de login
  /// para quem já tem sessão salva.
  bool _isReady = false;
  bool get isReady => _isReady;

  void _onUserChanged(AppUser? user) {
    _user = user;
    _isReady = true;
    notifyListeners();
  }

  Future<String?> signOut() async {
    final Result<void> result = await _signOut();
    return result.fold((failure) => failure.message, (_) => null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
