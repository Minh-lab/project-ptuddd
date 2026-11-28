import '../../features/notes/domain/entities/note.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/reminders/domain/entities/reminder_note.dart';
import '../../features/reminders/domain/repositories/reminder_note_source.dart';

/// Cho feature reminders đọc ghi chú qua [NoteRepository] mà không import chéo
/// feature notes (#10). Chỉ `core/di` được biết cả hai feature.
class ReminderNoteAdapter implements ReminderNoteSource {
  ReminderNoteAdapter(this._notes);

  final NoteRepository _notes;

  @override
  Stream<List<ReminderNote>> watchNotes() =>
      _notes.watchNotes().map(_toReminderNotes);

  @override
  Future<List<ReminderNote>> getNotes() async =>
      _toReminderNotes(await _notes.getNotes());

  static List<ReminderNote> _toReminderNotes(
    List<Note> notes,
  ) => <ReminderNote>[
    for (final note in notes)
      if (note.deletedAt == null) ReminderNote(id: note.id, title: note.title),
  ];
}
