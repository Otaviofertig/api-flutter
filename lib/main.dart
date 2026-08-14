import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/datasources/firebase_bootstrap.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/views/auth_gate.dart';

/// Composition root: é o único lugar que conhece implementações concretas.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ordem importa: o `.env` alimenta o cliente HTTP e o Firebase.
  final AppConfig config = await AppConfig.load();
  final bool isAuthEnabled = await FirebaseBootstrap.initialize(config.firebase);

  await setupInjector(config, isAuthEnabled: isAuthEnabled);

  runApp(LibriaApp(isAuthEnabled: isAuthEnabled));
}

/// Raiz do Libria. Não conhece regra de negócio: só tema, sessão e DI.
class LibriaApp extends StatelessWidget {
  const LibriaApp({super.key, required this.isAuthEnabled});

  final bool isAuthEnabled;

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = sl<ThemeController>();

    // A raiz é o único ponto alto o bastante para trocar o tema do app
    // inteiro; por isso quem escuta o controller é ela, e não as telas.
    return ListenableBuilder(
      listenable: theme,
      builder: (BuildContext context, Widget? child) => MaterialApp(
        title: 'Libria',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: theme.mode,
        home: child,
      ),
      // Fora do builder: a árvore de telas não precisa remontar a cada troca
      // de tema — só o MaterialApp acima dela muda.
      child: AuthGate(
        controller: sl<AuthController>(),
        isAuthEnabled: isAuthEnabled,
      ),
    );
  }
}
