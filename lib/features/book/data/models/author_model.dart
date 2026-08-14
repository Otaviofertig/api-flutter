import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/author.dart';

/// DTO de [Author] para `GET /authors/{id}.json`.
///
/// Toda a tolerância a formato fica aqui: o endpoint devolve `bio` ora como
/// String, ora como `{type, value}`, e `photos` com `-1` no lugar de omitir o
/// campo quando não há retrato.
final class AuthorModel extends Author {
  const AuthorModel({
    required super.id,
    required super.name,
    super.bio,
    super.birthDate,
    super.deathDate,
    super.photoId,
    super.alternateNames,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    return AuthorModel(
      id: ApiConstants.normalizeAuthorId(_string(json['key']) ?? fallbackId ?? ''),
      name: _string(json['name']) ??
          _string(json['personal_name']) ??
          'Autor sem nome registrado',
      bio: _bio(json['bio']),
      birthDate: _string(json['birth_date']),
      deathDate: _string(json['death_date']),
      photoId: _firstPhoto(json['photos']),
      alternateNames: _stringList(json['alternate_names']),
    );
  }

  // --- Coerção defensiva -----------------------------------------------------

  /// `bio` alterna entre String e `{type, value}`, igual a `description` da obra.
  static String? _bio(Object? value) {
    if (value is String) return _string(value);
    if (value is Map && value['value'] is String) return _string(value['value']);
    return null;
  }

  /// Primeiro retrato válido. A API usa `-1` para "sem foto" em vez de omitir.
  static int? _firstPhoto(Object? value) {
    if (value is! List) return null;

    for (final Object? entry in value) {
      final int? id = entry is num ? entry.toInt() : int.tryParse('$entry');
      if (id != null && id > 0) return id;
    }
    return null;
  }

  static String? _string(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value.map(_string).whereType<String>().toList(growable: false);
  }
}
