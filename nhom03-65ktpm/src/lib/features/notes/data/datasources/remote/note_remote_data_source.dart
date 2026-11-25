import '../../../domain/entities/note.dart';

abstract interface class NoteRemoteDataSource {
  Future<List<Note>> fetchNotes(String userId);
}
