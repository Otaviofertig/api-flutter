import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'features/book/presentation/views/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ordem importa: a configuração do `.env` alimenta o cliente HTTP.
  final AppConfig config = await AppConfig.load();
  await setupInjector(config);

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
      home: const HomePage(),
    );
  }
}
