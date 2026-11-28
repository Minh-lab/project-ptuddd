import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/sync/sync_status.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import 'notes_state.dart';

/// Giữ danh sách ghi chú cho màn hình chính.
///
/// Widget không đọc database trực tiếp: mọi thứ đi qua cubit này.
class NotesCubit extends Cubit<NotesState> {
  NotesCubit(
    this._repository, {
    SyncMonitor? monitor,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(NotesState(syncStatus: monitor?.status ?? SyncStatus.disabled)) {
    _syncSubscription = monitor?.stream.listen((SyncStatus status) {
      emit(
        state.copyWith(
          syncStatus: status,
          syncMessage: monitor.lastMessage,
          clearSyncMessage: monitor.lastMessage == null,
        ),
      );
    });
  }

  final NoteRepository _repository;
  final DateTime Function() _clock;
  StreamSubscription<List<Note>>? _subscription;
  StreamSubscription<SyncStatus>? _syncSubscription;
  final Map<String, Future<Note>> _pendingDiaryCreations =
      <String, Future<Note>>{};

  /// Bắt đầu theo dõi dữ liệu; gọi một lần khi màn hình được tạo.
  Future<void> load() async {
    emit(state.copyWith(status: NotesStatus.loading, errorMessage: null));
    await _subscription?.cancel();
    try {
      await ensureDiaryForDate(DateTime.now());
    } on Object catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: NotesStatus.failure,
            errorMessage: error is Failure ? error.message : '$error',
          ),
        );
      }
      return;
    }
    if (isClosed) return;
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
    DateTime? createdAt,
  }) async {
    final now = _clock();
    final note = Note(
      // Bảng `notes` trên Supabase dùng khoá `uuid`, nên id sinh ngay trên máy
      // cũng phải là UUID v4 (#21).
      id: const Uuid().v4(),
      title: title,
      content: content,
      kind: kind,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
    await _repository.createNote(note);
    return note;
  }

  /// Trả về nhật ký của ngày địa phương, chỉ tạo mới nếu chưa có.
  ///
  /// Các lần gọi đồng thời trong cùng cubit dùng chung một thao tác tạo.
  Future<Note> ensureDiaryForDate(DateTime date) {
    final localDate = date.toLocal();
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final pending = _pendingDiaryCreations[key];
    if (pending != null) return pending;

    final creation = _findOrCreateDiary(day);
    _pendingDiaryCreations[key] = creation;
    return creation.whenComplete(() {
      if (identical(_pendingDiaryCreations[key], creation)) {
        _pendingDiaryCreations.remove(key);
      }
    });
  }

  Future<Note> _findOrCreateDiary(DateTime day) async {
    final notes = await _repository.getNotes();
    for (final note in notes) {
      final createdAt = note.createdAt.toLocal();
      if (note.isDiary &&
          createdAt.year == day.year &&
          createdAt.month == day.month &&
          createdAt.day == day.day) {
        return note;
      }
    }

    final now = _clock();
    final dateLabel =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return createNote(
      title: 'Nhật ký $dateLabel',
      content: '',
      kind: NoteKind.diary,
      createdAt: DateTime(
        day.year,
        day.month,
        day.day,
        now.hour,
        now.minute,
        now.second,
        now.millisecond,
        now.microsecond,
      ),
    );
  }

  Future<void> updateNote(Note note, {String? title, String? content}) async {
    await _repository.updateNote(
      note.copyWith(title: title, content: content, updatedAt: _clock()),
    );
  }

  Future<void> deleteNote(String id) => _repository.deleteNote(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _syncSubscription?.cancel();
    return super.close();
  }
}
