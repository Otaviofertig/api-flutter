import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Botão de tema da AppBar: abre as três opções (sistema, claro, escuro).
///
/// Menu em vez de alternância direta porque *voltar a seguir o aparelho* não
/// cabe num toggle de dois estados — e escondê-lo num gesto secundário seria
/// o mesmo que não ter a opção.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key, required this.controller});

  final ThemeController controller;

  static const Map<ThemeMode, ({IconData icon, String label})> _options =
      <ThemeMode, ({IconData icon, String label})>{
    ThemeMode.system: (icon: Icons.brightness_auto_rounded, label: 'Seguir o sistema'),
    ThemeMode.light: (icon: Icons.light_mode_rounded, label: 'Claro'),
    ThemeMode.dark: (icon: Icons.dark_mode_rounded, label: 'Escuro'),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        // O ícone mostra o tema que está valendo, não o modo escolhido: em
        // "seguir o sistema" o modo sozinho não diz se a tela está escura.
        final bool dark = controller.isDark(context);

        return PopupMenuButton<ThemeMode>(
          tooltip: 'Tema: ${_options[controller.mode]!.label}',
          offset: const Offset(0, 48),
          initialValue: controller.mode,
          onSelected: controller.setMode,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Meia volta na troca: o sol vira lua em vez de piscar.
              return RotationTransition(
                turns: Tween<double>(begin: 0.5, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey<bool>(dark),
            ),
          ),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
            for (final MapEntry<ThemeMode, ({IconData icon, String label})> option
                in _options.entries)
              PopupMenuItem<ThemeMode>(
                value: option.key,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(option.value.icon),
                  title: Text(option.value.label),
                  trailing: controller.mode == option.key
                      ? const Icon(Icons.check_rounded)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}
