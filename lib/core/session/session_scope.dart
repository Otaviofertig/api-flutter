/// Dono dos dados locais no momento.
///
/// Existe para que dados por usuário (estante, caches) não fiquem numa chave
/// global compartilhada entre contas do mesmo aparelho. A feature `book`
/// depende só deste contrato — quem sabe o que é uma sessão é a `auth`, e a
/// ligação entre as duas acontece na composition root.
abstract interface class ISessionScope {
  /// Identificador estável do dono dos dados, ou `null` quando ninguém está
  /// autenticado: app sem Firebase configurado ou sessão encerrada.
  String? get scopeId;
}

/// Escopo usado quando não existe autenticação — os dados pertencem ao
/// aparelho, não a uma conta.
///
/// Null Object: com o Firebase desligado a injeção continua resolvendo e a
/// estante segue funcionando como antes do login existir.
final class AnonymousSessionScope implements ISessionScope {
  const AnonymousSessionScope();

  @override
  String? get scopeId => null;
}
