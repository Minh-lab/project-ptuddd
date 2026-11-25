import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';
import 'package:smart_note/features/notes/data/datasources/remote/note_remote_data_source.dart';
import 'package:smart_note/features/notes/data/repositories/note_repository_impl.dart';
import 'package:smart_note/features/notes/data/repositories/supabase_note_repository.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';

void main() {
  late AppDatabase database;
  late NotesDao notesDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    notesDao = NotesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('watchNotes tải ghi chú theo UID rồi lưu vào Drift', () async {
    final remoteDataSource = _FakeNoteRemoteDataSource(<Note>[_remoteNote]);
    final repository = SupabaseNoteRepository(
      NoteRepositoryImpl(notesDao),
      notesDao,
      remoteDataSource,
      () => 'firebase-user-1',
    );
    final loaded = Completer<void>();
    final subscription = repository.watchNotes().listen((notes) {
      if (notes.any((note) => note.id == _remoteNote.id) &&
          !loaded.isCompleted) {
        loaded.complete();
      }
    }, onError: loaded.completeError);

    try {
      await loaded.future.timeout(const Duration(seconds: 2));

      expect(remoteDataSource.requestedUserId, 'firebase-user-1');
      final cached = await notesDao.findById(_remoteNote.id);
      expect(cached, isNotNull);
      expect(cached!.title, _remoteNote.title);
      expect(cached.content, _remoteNote.content);
    } finally {
      await subscription.cancel();
    }
  });
}

final Note _remoteNote = Note(
  id: 'e1111111-1111-4111-8111-111111111111',
  title: 'Ghi chú trên Supabase',
  content: 'Nội dung tải về',
  kind: NoteKind.note,
  createdAt: DateTime.utc(2026, 11, 25),
  updatedAt: DateTime.utc(2026, 11, 26),
  tags: const <String>['nhóm'],
);

class _FakeNoteRemoteDataSource implements NoteRemoteDataSource {
  _FakeNoteRemoteDataSource(this.notes);

  final List<Note> notes;
  String? requestedUserId;

  @override
  Future<List<Note>> fetchNotes(String userId) async {
    requestedUserId = userId;
    return notes;
  }
}
