import '../../domain/entities/reading_status.dart';
import '../../domain/entities/shelf_entry.dart';
import 'book_model.dart';

/// DTO de [ShelfEntry] para o armazenamento local.
///
/// O formato gravado é o do livro **acrescido** de `status`, e não um objeto
/// aninhado: assim a estante escrita antes desta feature continua legível, e
/// registro sem `status` volta como [ReadingStatus.initial] sem migração.
final class ShelfEntryModel extends ShelfEntry {
  const ShelfEntryModel({required BookModel super.book, super.status});

  factory ShelfEntryModel.fromLocalJson(Map<String, dynamic> json) {
    return ShelfEntryModel(
      book: BookModel.fromLocalJson(json),
      status: ReadingStatus.fromStorage(json['status']),
    );
  }

  factory ShelfEntryModel.fromEntity(ShelfEntry entry) {
    return ShelfEntryModel(
      book: BookModel.fromEntity(entry.book),
      status: entry.status,
    );
  }

  BookModel get bookModel => book as BookModel;

  Map<String, dynamic> toLocalJson() => <String, dynamic>{
        ...bookModel.toLocalJson(),
        'status': status.storageKey,
      };

  @override
  ShelfEntryModel withStatus(ReadingStatus status) =>
      ShelfEntryModel(book: bookModel, status: status);
}
