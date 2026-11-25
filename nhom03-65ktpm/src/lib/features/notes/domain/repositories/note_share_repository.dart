import '../entities/note.dart';
import '../entities/note_share.dart';

abstract interface class NoteShareRepository {
  Future<List<NoteShare>> listForNote({
    required String sourceNoteId,
    required String ownerId,
  });

  Future<NoteShare> create({
    required Note note,
    required String recipientId,
  });

  Future<void> revoke(String shareId);

  Future<Note> openSharedNote({
    required String shareId,
    required String recipientId,
  });
}
