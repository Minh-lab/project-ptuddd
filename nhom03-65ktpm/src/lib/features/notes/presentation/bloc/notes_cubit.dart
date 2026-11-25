import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/note_search.dart';
import 'notes_state.dart';

/// Giữ danh sách ghi chú cho màn hình chính.
///
/// Widget không đọc database trực tiếp: mọi thứ đi qua cubit này.
class NotesCubit extends Cubit<NotesState> {
  NotesCubit(this._repository, {this._noteSearch = const NoteSearch()})
    : super(const NotesState());

  final NoteRepository _repository;
  final NoteSearch _noteSearch;
  StreamSubscription<List<Note>>? _subscription;
  Timer? _searchTimer;
  List<Note> _allNotes = const <Note>[];
  String _searchQuery = '';

  static const Duration searchDebounceDuration = Duration(milliseconds: 300);

  /// Bắt đầu theo dõi dữ liệu; gọi một lần khi màn hình được tạo.
  Future<void> load() async {
    emit(state.copyWith(status: NotesStatus.loading, errorMessage: null));
    await _subscription?.cancel();
    _subscription = _repository.watchNotes().listen(
      (List<Note> notes) {
        _allNotes = notes;
        _emitFilteredNotes(dataUpdated: true);
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

  /// Áp dụng truy vấn sau một khoảng ngắn để tránh lọc lại sau từng phím gõ.
  void search(String query) {
    _searchQuery = query;
    emit(state.copyWith(searchQuery: query));
    _searchTimer?.cancel();
    if (query.trim().isEmpty) {
      _emitFilteredNotes();
      return;
    }
    _searchTimer = Timer(searchDebounceDuration, _emitFilteredNotes);
  }

  void _emitFilteredNotes({bool dataUpdated = false}) {
    emit(
      state.copyWith(
        status: dataUpdated ? NotesStatus.success : state.status,
        notes: _noteSearch(_allNotes, _searchQuery),
        searchQuery: _searchQuery,
        errorMessage: dataUpdated ? null : state.errorMessage,
      ),
    );
  }

  @override
  Future<void> close() async {
    _searchTimer?.cancel();
    await _subscription?.cancel();
    return super.close();
  }
}
