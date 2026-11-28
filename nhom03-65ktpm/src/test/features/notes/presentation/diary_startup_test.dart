import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/features/notes/domain/entities/note.dart';
import 'package:smart_note/features/notes/domain/repositories/note_repository.dart';
import 'package:smart_note/features/notes/presentation/bloc/notes_cubit.dart';

class DelayedDiaryRepository implements NoteRepository {
  final createStarted = Completer<void>();
  final pendingSync = Completer<void>();
  bool watching = false;

  @override
  Future<List<Note>> getNotes() async => <Note>[];

  @override
  Future<void> createNote(Note note) {
    createStarted.complete();
    return pendingSync.future;
  }

  @override
  Stream<List<Note>> watchNotes() {
    watching = true;
    return Stream.value(<Note>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('display notes while first diary sync has not finished', () async {
    final repository = DelayedDiaryRepository();
    final cubit = NotesCubit(repository);
    final load = cubit.load();
    await repository.createStarted.future;
    final watchedBeforeSync = repository.watching;
    repository.pendingSync.complete();
    await load;
    await cubit.close();
    expect(watchedBeforeSync, isTrue);
  });
}
