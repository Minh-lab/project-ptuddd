import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';

/// Ghi chú giả trong bộ nhớ, chỉ dùng ở Development Mode.
class DevelopmentNoteRepository implements NoteRepository {
  DevelopmentNoteRepository() {
    final now = DateTime.now();
    _notes = <Note>[
      Note(
        id: 'development-note-1',
        title: 'Ghi chú phát triển',
        content: 'Dữ liệu mẫu chỉ tồn tại trong phiên chạy hiện tại.',
        kind: NoteKind.note,
        createdAt: now,
        updatedAt: now,
        tags: const <String>['mẫu', 'development'],
      ),
      Note(
        id: 'development-note-2',
        title: 'Ý tưởng SmartNote',
        content: 'Thử nghiệm giao diện mà không cần kết nối Firebase.',
        kind: NoteKind.note,
        createdAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now.subtract(const Duration(minutes: 1)),
        tags: const <String>['SmartNote'],
      ),
    ];
  }

  late List<Note> _notes;
  final StreamController<List<Note>> _controller =
      StreamController<List<Note>>.broadcast();

  @override
  Stream<List<Note>> watchNotes() async* {
    yield _sortedNotes;
    yield* _controller.stream;
  }

  @override
  Future<List<Note>> getNotes() async => _sortedNotes;

  @override
  Future<Note?> findById(String id) async {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Future<void> createNote(Note note) async {
    _notes.removeWhere((Note existing) => existing.id == note.id);
    _notes.add(note);
    _notifyChanged();
  }

  @override
  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((Note existing) => existing.id == note.id);
    if (index < 0) {
      throw const DatabaseFailure('Không tìm thấy ghi chú để cập nhật');
    }
    _notes[index] = note;
    _notifyChanged();
  }

  @override
  Future<void> deleteNote(String id) async {
    final exists = _notes.any((Note note) => note.id == id);
    if (!exists) {
      throw const DatabaseFailure('Không tìm thấy ghi chú để xoá');
    }
    _notes.removeWhere((Note note) => note.id == id);
    _notifyChanged();
  }

  List<Note> get _sortedNotes {
    final notes = List<Note>.of(_notes)
      ..sort(
        (Note left, Note right) => right.updatedAt.compareTo(left.updatedAt),
      );
    return notes;
  }

  void _notifyChanged() {
    _controller.add(_sortedNotes);
  }

  Future<void> dispose() => _controller.close();
}
