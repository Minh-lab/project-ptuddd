import '../../features/notes/domain/entities/note.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/stats/domain/entities/study_note.dart';
import '../../features/stats/domain/repositories/study_activity_source.dart';

/// Cho feature stats đọc ghi chú qua [NoteRepository] mà không import chéo
/// feature notes (#17). Chỉ `core/di` được biết cả hai feature.
class StudyActivityAdapter implements StudyActivitySource {
  StudyActivityAdapter(this._notes);

  final NoteRepository _notes;

  @override
  Stream<List<StudyNote>> watchStudyNotes() {
    return _notes.watchNotes().map(
      (List<Note> notes) => <StudyNote>[
        for (final note in notes)
          if (note.deletedAt == null)
            StudyNote(
              id: note.id,
              createdAt: note.createdAt,
              isDiary: note.kind == NoteKind.diary,
            ),
      ],
    );
  }
}
