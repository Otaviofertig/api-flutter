/// Usuário autenticado, na linguagem do domínio.
///
/// Nada de `User` do Firebase circulando pelo app: trocar de provedor
/// (Firebase, Supabase, backend próprio) não toca nesta classe.
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.providers = const <String>[],
  });

  /// UID estável do provedor.
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;

  /// Provedores vinculados (`password`, `google.com`, ...).
  final List<String> providers;

  /// Nome para exibição, com queda para o e-mail e, por fim, um genérico.
  String get label {
    final String? name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final String? mail = email?.trim();
    if (mail != null && mail.isNotEmpty) return mail.split('@').first;

    return 'Leitor(a)';
  }

  /// Iniciais para o avatar quando não há foto.
  String get initials {
    final List<String> parts = label
        .split(RegExp(r'[\s._-]+'))
        .where((String p) => p.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  bool get isFromGoogle => providers.contains('google.com');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppUser && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppUser($id, ${email ?? "sem e-mail"})';
}
