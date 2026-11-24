import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import 'notes_state.dart';

/// Giữ danh sách ghi chú cho màn hình chính.
///
/// Widget không đọc database trực tiếp: mọi thứ đi qua cubit này.
class NotesCubit extends Cubit<NotesState> {
  NotesCubit(this._repository) : super(const NotesState());

  final NoteRepository _repository;
  StreamSubscription<List<Note>>? _subscription;

  /// Bắt đầu theo dõi dữ liệu; gọi một lần khi màn hình được tạo.
  Future<void> load() async {
    emit(state.copyWith(status: NotesStatus.loading, errorMessage: null));
    await _subscription?.cancel();
    _subscription = _repository.watchNotes().listen(
      (List<Note> notes) {
        emit(
          state.copyWith(
            status: NotesStatus.success,
            notes: notes,
            errorMessage: null,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: NotesStatus.failure,
            errorMessage: error is Failure ? error.message : '$error',
          ),
        );
      },
    );
  }

  Future<Note> createNote({
    required String title,
    required String content,
    NoteKind kind = NoteKind.note,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: '${now.microsecondsSinceEpoch}-${now.hashCode}',
      title: title,
      content: content,
      kind: kind,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.createNote(note);
    return note;
  }

  Future<void> updateNote(Note note, {String? title, String? content}) async {
    await _repository.updateNote(
      note.copyWith(title: title, content: content, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteNote(String id) => _repository.deleteNote(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
