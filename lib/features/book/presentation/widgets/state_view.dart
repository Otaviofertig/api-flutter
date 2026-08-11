import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';

/// Mensagem centralizada para os estados vazio / erro / inicial.
///
/// Centraliza o vocabulário visual desses estados: qualquer tela do app
/// comunica erro da mesma forma.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Constrói o estado de erro a partir de um [Failure] do domínio.
  factory StateView.fromFailure(Failure failure, {VoidCallback? onRetry}) {
    final IconData icon = switch (failure) {
      NetworkFailure() => Icons.wifi_off_rounded,
      TimeoutFailure() => Icons.hourglass_disabled_rounded,
      ValidationFailure() => Icons.edit_note_rounded,
      CacheFailure() => Icons.sd_card_alert_outlined,
      _ => Icons.error_outline_rounded,
    };

    return StateView(
      icon: icon,
      title: 'Algo não saiu como esperado',
      message: failure.message,
      actionLabel: onRetry == null ? null : 'Tentar novamente',
      onAction: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (onAction != null && actionLabel != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
