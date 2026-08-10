import 'dart:async';

/// Agenda uma ação e cancela a anterior a cada nova chamada.
///
/// Usado na busca para disparar apenas uma requisição quando o usuário para
/// de digitar, em vez de uma por tecla.
final class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 450)});

  final Duration duration;
  Timer? _timer;

  bool get isActive => _timer?.isActive ?? false;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Executa imediatamente, descartando o agendamento pendente.
  void runNow(void Function() action) {
    cancel();
    action();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
