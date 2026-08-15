import 'package:flutter/material.dart';

import '../../domain/entities/reading_status.dart';

/// Ícone de cada prateleira. Fica na apresentação, não na entidade: o domínio
/// não conhece Material.
IconData iconForStatus(ReadingStatus status) {
  return switch (status) {
    ReadingStatus.wantToRead => Icons.bookmark_add_outlined,
    ReadingStatus.reading => Icons.auto_stories_rounded,
    ReadingStatus.read => Icons.check_circle_rounded,
  };
}

/// Botão sobreposto à capa, na estante: mostra a prateleira atual e permite
/// mudar de prateleira ou tirar o livro.
///
/// Um menu só em vez de dois botões — o espaço sobre a capa não comporta
/// quatro alvos de toque sem virar um campo minado.
class ReadingStatusMenu extends StatelessWidget {
  const ReadingStatusMenu({
    super.key,
    required this.status,
    required this.onSelected,
    required this.onRemove,
  });

  final ReadingStatus status;
  final void Function(ReadingStatus status) onSelected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<_ShelfAction>(
        tooltip: status.label,
        icon: Icon(iconForStatus(status), size: 20),
        iconSize: 20,
        onSelected: (_ShelfAction action) => switch (action) {
          _Move(:final ReadingStatus target) => onSelected(target),
          _Remove() => onRemove(),
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_ShelfAction>>[
          for (final ReadingStatus option in ReadingStatus.values)
            PopupMenuItem<_ShelfAction>(
              value: _Move(option),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(iconForStatus(option)),
                title: Text(option.label),
                trailing: option == status ? const Icon(Icons.check_rounded) : null,
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<_ShelfAction>(
            value: const _Remove(),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.bookmark_remove_outlined, color: scheme.error),
              title: Text(
                'Tirar da estante',
                style: TextStyle(color: scheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O menu mistura duas coisas — mudar de prateleira e sair da estante. Um tipo
/// selado deixa o `switch` do `onSelected` verificado pelo compilador, em vez
/// de um enum com um valor sobrando.
sealed class _ShelfAction {
  const _ShelfAction();
}

final class _Move extends _ShelfAction {
  const _Move(this.target);

  final ReadingStatus target;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _Move && other.target == target);

  @override
  int get hashCode => target.hashCode;
}

final class _Remove extends _ShelfAction {
  const _Remove();

  @override
  bool operator ==(Object other) => identical(this, other) || other is _Remove;

  @override
  int get hashCode => 0;
}
