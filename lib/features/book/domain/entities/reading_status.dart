/// Em que ponto da leitura um livro da estante está.
///
/// A [storageKey] é o que vai para o disco, separada do nome do valor de
/// propósito: renomear `wantToRead` no código não pode invalidar a estante já
/// gravada de ninguém.
enum ReadingStatus {
  wantToRead('quero_ler', 'Quero ler'),
  reading('lendo', 'Lendo'),
  read('lido', 'Lido');

  const ReadingStatus(this.storageKey, this.label);

  /// Chave persistida. Nunca mude um valor destes sem migração.
  final String storageKey;

  /// Rótulo exibido na UI.
  final String label;

  /// Estado de quem acabou de salvar um livro: guardou para ler depois.
  ///
  /// É também o destino da estante criada antes desta feature existir, onde
  /// os livros foram salvos sem status nenhum.
  static const ReadingStatus initial = ReadingStatus.wantToRead;

  /// Lê a chave gravada, caindo em [initial] no que não reconhecer.
  static ReadingStatus fromStorage(Object? raw) {
    if (raw is! String) return initial;

    for (final ReadingStatus status in values) {
      if (status.storageKey == raw) return status;
    }
    return initial;
  }
}
