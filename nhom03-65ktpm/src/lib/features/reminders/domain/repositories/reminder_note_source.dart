import '../entities/reminder_note.dart';

/// Nguồn ghi chú cho feature nhắc nhở.
///
/// Hiện thực nằm ở `core/di` (bọc `NoteRepository`), nhờ vậy feature này
/// không import feature notes.
abstract interface class ReminderNoteSource {
  Stream<List<ReminderNote>> watchNotes();

  Future<List<ReminderNote>> getNotes();
}
