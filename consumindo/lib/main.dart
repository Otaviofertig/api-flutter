import 'package:flutter/material.dart';

import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupInjector();
  runApp(const LibriaApp());
}

/// Raiz do Libria. Não conhece regra de negócio: só tema, rotas e DI.
class LibriaApp extends StatelessWidget {
  const LibriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libria',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('Libria — camadas core/data/domain prontas.'),
        ),
      ),
    );
  }
}
