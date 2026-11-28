import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'note_attachments_dao.g.dart';

/// Truy cập bảng [NoteAttachments] — lưu đường dẫn ảnh gốc/ảnh cắt và kết quả OCR.
@DriftAccessor(tables: [NoteAttachments])
class NoteAttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$NoteAttachmentsDaoMixin {
  NoteAttachmentsDao(super.db);

  /// Lưu bản ghi đính kèm ảnh vào cơ sở dữ liệu cục bộ.
  Future<void> insertAttachment(NoteAttachmentsCompanion row) =>
      into(noteAttachments).insert(row);

  /// Lấy danh sách ảnh đính kèm của một ghi chú theo thứ tự trang.
  Future<List<NoteAttachmentRow>> getByNoteId(String noteId) {
    final query = select(noteAttachments)
      ..where((NoteAttachments t) => t.noteId.equals(noteId))
      ..orderBy([(NoteAttachments t) => OrderingTerm.asc(t.pageOrder)]);
    return query.get();
  }

  /// Theo dõi danh sách ảnh đính kèm của một ghi chú.
  Stream<List<NoteAttachmentRow>> watchByNoteId(String noteId) {
    final query = select(noteAttachments)
      ..where((NoteAttachments t) => t.noteId.equals(noteId))
      ..orderBy([(NoteAttachments t) => OrderingTerm.asc(t.pageOrder)]);
    return query.watch();
  }
}
