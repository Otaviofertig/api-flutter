import 'package:flutter/material.dart';

import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

/// Avatar do usuário na AppBar, com a ação de sair.
///
/// Some sozinho quando não há sessão (app rodando sem Firebase), então a
/// Home não precisa saber se a autenticação existe.
class UserMenu extends StatelessWidget {
  const UserMenu({super.key, required this.controller});

  final AuthController controller;

  Future<void> _signOut(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? error = await controller.signOut();

    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final AppUser? user = controller.user;
        if (user == null) return const SizedBox.shrink();

        return PopupMenuButton<void>(
          tooltip: user.label,
          offset: const Offset(0, 48),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<void>>[
            PopupMenuItem<void>(
              enabled: false,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(user.label),
                subtitle: user.email == null ? null : Text(user.email!),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<void>(
              onTap: () => _signOut(context),
              child: const ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded),
                title: Text('Sair'),
              ),
            ),
          ],
          child: _Avatar(user: user),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? photo = user.photoUrl;

    return CircleAvatar(
      radius: 16,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: photo == null ? null : NetworkImage(photo),
      child: Text(
        user.initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
