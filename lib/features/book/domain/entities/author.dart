/// Um autor da Open Library (`/authors/{id}.json`).
///
/// Entidade pura: a URL do retrato é montada na apresentação a partir de
/// [photoId], pelo mesmo motivo que [Book] não guarda URL de capa.
class Author {
  const Author({
    required this.id,
    required this.name,
    this.bio,
    this.birthDate,
    this.deathDate,
    this.photoId,
    this.alternateNames = const <String>[],
  });

  /// Id sem prefixo, como `OL26320A`.
  final String id;
  final String name;
  final String? bio;

  /// Datas chegam em texto livre: "31 July 1965", "1892", "3 Jan 1892".
  /// Guardar como String é honesto — parsear daria uma precisão que a fonte
  /// não tem.
  final String? birthDate;
  final String? deathDate;

  final int? photoId;
  final List<String> alternateNames;

  bool get hasBio => bio?.trim().isNotEmpty ?? false;
  bool get hasPhoto => photoId != null && photoId! > 0;

  /// Linha de vida pronta para exibir, ou `null` quando não há data nenhuma.
  ///
  /// Um autor vivo tem nascimento sem morte; um autor antigo pode ter só o
  /// ano de morte registrado. Os três casos rendem rótulos diferentes.
  String? get lifespanLabel {
    final String? birth = _clean(birthDate);
    final String? death = _clean(deathDate);

    return switch ((birth, death)) {
      (null, null) => null,
      (final String b, null) => 'Nascimento: $b',
      (null, final String d) => 'Falecimento: $d',
      (final String b, final String d) => '$b — $d',
    };
  }

  /// Iniciais para o avatar quando não há retrato.
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);

    return switch (parts.length) {
      0 => '?',
      1 => _firstLetter(parts.first),
      _ => '${_firstLetter(parts.first)}${_firstLetter(parts.last)}',
    };
  }

  static String _firstLetter(String word) => word[0].toUpperCase();

  static String? _clean(String? value) {
    final String? trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Author && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Author($id, $name)';
}
