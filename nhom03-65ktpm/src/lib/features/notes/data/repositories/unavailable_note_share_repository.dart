import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_share.dart';
import '../../domain/entities/received_note_share.dart';
import '../../domain/repositories/note_share_repository.dart';

class UnavailableNoteShareRepository implements NoteShareRepository {
  UnavailableNoteShareRepository([
    this.message = 'Chưa cấu hình Supabase. Điền SUPABASE_URL và SUPABASE_PUBLISHABLE_KEY trong src/.env.',
  ]);

  final String message;

  Never _throwUnavailable() => throw DatabaseFailure(message);

  @override
  Future<List<NoteShare>> listForNote({
    required String sourceNoteId,
    required String ownerId,
  }) async {
    _throwUnavailable();
  }

  @override
  Future<List<ReceivedNoteShare>> listReceived() async {
    _throwUnavailable();
  }

  @override
  Future<NoteShare> create({
    required Note note,
    required String recipientEmail,
  }) async {
    _throwUnavailable();
  }

  @override
  Future<void> revoke(String shareId) async {
    _throwUnavailable();
  }

  @override
  Future<Note> openSharedNote({
    required String shareId,
    required String recipientId,
  }) async {
    _throwUnavailable();
  }
}
