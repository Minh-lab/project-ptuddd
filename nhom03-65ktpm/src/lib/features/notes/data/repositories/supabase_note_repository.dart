import 'dart:async';

import 'package:drift/drift.dart';

import '../../../../core/database/notes_dao.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/remote/note_remote_data_source.dart';
import '../models/note_mapper.dart';

class SupabaseNoteRepository implements NoteRepository {
  SupabaseNoteRepository(
    this._localRepository,
    this._notesDao,
    this._remoteDataSource,
    this._currentUserId,
  );

  final NoteRepository _localRepository;
  final NotesDao _notesDao;
  final NoteRemoteDataSource _remoteDataSource;
  final String? Function() _currentUserId;

  @override
  Stream<List<Note>> watchNotes() {
    return Stream<List<Note>>.multi((controller) {
      final localSubscription = _localRepository.watchNotes().listen(
        controller.add,
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );
      controller.onCancel = localSubscription.cancel;

      unawaited(
        _syncRemoteNotes().catchError((Object error, StackTrace stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        }),
      );
    });
  }

  @override
  Future<List<Note>> getNotes() => _localRepository.getNotes();

  @override
  Future<Note?> findById(String id) => _localRepository.findById(id);

  @override
  Future<void> createNote(Note note) => _localRepository.createNote(note);

  @override
  Future<void> updateNote(Note note) => _localRepository.updateNote(note);

  @override
  Future<void> deleteNote(String id) => _localRepository.deleteNote(id);

  Future<void> _syncRemoteNotes() async {
  final userId = _currentUserId();

  debugPrint('========== SUPABASE SYNC ==========');
  debugPrint('Firebase UID: $userId');

  if (userId == null || userId.isEmpty) {
    throw const DatabaseFailure(
      'Cần đăng nhập Firebase để tải ghi chú từ Supabase.',
    );
  }

  try {
    debugPrint('Đang gọi Supabase lấy notes...');

    final remoteNotes = await _remoteDataSource.fetchNotes(userId);

    debugPrint('Supabase trả về ${remoteNotes.length} ghi chú');

    for (final note in remoteNotes) {
      debugPrint('Đang lưu note: ${note.title}');

      await _notesDao.upsertSyncedNote(
        note.toCompanion().copyWith(
          userId: Value(userId),
          deletedAt: const Value<DateTime?>(null),
        ),
      );
    }

    debugPrint('Đồng bộ hoàn thành!');
    debugPrint('==================================');
  } on Failure {
    rethrow;
  } on Object catch (error) {
    debugPrint('LỖI SYNC: $error');
    throw DatabaseFailure('Không đồng bộ được ghi chú: $error');
  }
}
}
