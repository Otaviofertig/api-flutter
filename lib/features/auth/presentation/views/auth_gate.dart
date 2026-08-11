import 'package:flutter/material.dart';

import '../../../book/presentation/views/home_page.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

/// Decide a tela inicial de acordo com a sessão.
///
/// Único ponto de decisão sobre "logado ou não": nenhuma tela precisa
/// navegar manualmente depois de autenticar ou sair.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.controller, required this.isAuthEnabled});

  final AuthController controller;

  /// `false` quando o Firebase não está configurado: o app abre direto no
  /// acervo, que é público, em vez de travar numa tela de login inútil.
  final bool isAuthEnabled;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.controller.user?.id;
    widget.controller.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Descarta as telas abertas quando a sessão troca de dono.
  ///
  /// Detalhes e estante são empilhados no Navigator raiz, *acima* deste widget:
  /// trocar o filho do gate não as remove. Sem isso, quem faz logout continua
  /// vendo a estante da conta anterior por cima da tela de login.
  void _onSessionChanged() {
    final String? userId = widget.controller.user?.id;
    if (userId == _userId) return;

    _userId = userId;
    // `maybeOf`: em teste de widget o gate pode ser montado sem Navigator.
    Navigator.maybeOf(context)?.popUntil((Route<Object?> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAuthEnabled) return const HomePage();

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        if (!widget.controller.isReady) return const _SplashScreen();
        return widget.controller.isAuthenticated ? const HomePage() : const LoginPage();
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
