import 'package:flutter/material.dart';

import '../../../book/presentation/views/home_page.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

/// Decide a tela inicial de acordo com a sessão.
///
/// Único ponto de decisão sobre "logado ou não": nenhuma tela precisa
/// navegar manualmente depois de autenticar ou sair.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.controller, required this.isAuthEnabled});

  final AuthController controller;

  /// `false` quando o Firebase não está configurado: o app abre direto no
  /// acervo, que é público, em vez de travar numa tela de login inútil.
  final bool isAuthEnabled;

  @override
  Widget build(BuildContext context) {
    if (!isAuthEnabled) return const HomePage();

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        if (!controller.isReady) return const _SplashScreen();
        return controller.isAuthenticated ? const HomePage() : const LoginPage();
      },
    );
  }
}

/// Exibida no intervalo entre abrir o app e o Firebase responder se há
/// sessão salva — normalmente alguns milissegundos.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.local_library_rounded, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
