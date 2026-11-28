import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/notes_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/classified_note.dart';
import '../../domain/repositories/note_classification_repository.dart';
import '../models/subject_mapper.dart';

/// Hiện thực [NoteClassificationRepository] trên bảng `notes` của Drift.
class NoteClassificationRepositoryImpl implements NoteClassificationRepository {
  NoteClassificationRepositoryImpl(this._dao, {this.onChanged});

  final NotesDao _dao;
  final void Function()? onChanged;

  @override
  Stream<List<ClassifiedNote>> watchNotes() {
    return _dao.watchAll().map(
      (List<NoteRow> rows) =>
          rows.map((NoteRow row) => row.toClassifiedNote()).toList(),
    );
  }

  @override
  Future<void> classifyNote(
    String noteId, {
    required String? subjectId,
    required List<String> tags,
  }) async {
    try {
      final updated = await _dao.updateClassification(
        noteId,
        NotesCompanion(
          subjectId: Value<String?>(subjectId),
          tags: Value<String>(tagsToStorage(tags)),
        ),
      );
      if (!updated) {
        throw const DatabaseFailure('Không tìm thấy ghi chú để phân loại');
      }
      onChanged?.call();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DatabaseFailure('Không lưu được phân loại: $error');
    }
  }

  @override
  Future<void> renameTag(String from, String to) {
    return _rewriteTags(
      from,
      (List<String> tags) =>
          _withoutDuplicates(tags.map((String t) => t == from ? to : t)),
      action: 'đổi tên',
    );
  }

  @override
  Future<void> deleteTag(String tag) {
    return _rewriteTags(
      tag,
      (List<String> tags) => tags.where((String t) => t != tag).toList(),
      action: 'xoá',
    );
  }

  /// Sửa danh sách tag của mọi ghi chú đang có [tag], trong một giao dịch.
  Future<void> _rewriteTags(
    String tag,
    List<String> Function(List<String> tags) rewrite, {
    required String action,
  }) async {
    try {
      await _dao.transaction(() async {
        for (final row in await _dao.getAll()) {
          final tags = parseStoredTags(row.tags);
          if (!tags.contains(tag)) continue;
          await _dao.updateClassification(
            row.id,
            NotesCompanion(tags: Value<String>(tagsToStorage(rewrite(tags)))),
          );
        }
      });
      onChanged?.call();
    } on Object catch (error) {
      throw DatabaseFailure('Không $action được tag: $error');
    }
  }

  List<String> _withoutDuplicates(Iterable<String> tags) {
    final seen = <String>{};
    return tags.where((String t) => seen.add(t.toLowerCase())).toList();
  }
}
