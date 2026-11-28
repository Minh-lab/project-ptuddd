import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../utils/uuid_format.dart';
import 'app_database.dart';
import 'tables.dart';

part 'subjects_dao.g.dart';

/// Truy cập bảng [Subjects] — chỉ tầng `data` được dùng DAO này.
@DriftAccessor(tables: [Subjects, Notes])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  /// Theo dõi các môn chưa bị xoá, theo thứ tự tạo.
  Stream<List<SubjectRow>> watchAll() {
    final query = select(subjects)
      ..where((Subjects t) => t.deletedAt.isNull())
      ..orderBy([(Subjects t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  Future<List<SubjectRow>> getAll() {
    final query = select(subjects)
      ..where((Subjects t) => t.deletedAt.isNull())
      ..orderBy([(Subjects t) => OrderingTerm.asc(t.createdAt)]);
    return query.get();
  }

  Future<void> insertSubject(SubjectsCompanion row) =>
      into(subjects).insert(row);

  Future<List<SubjectRow>> syncSnapshot(String userId) {
    return transaction(() async {
      final rows = await select(subjects).get();
      for (final row in rows.where((row) => !isUuid(row.id))) {
        final id = const Uuid().v5(
          Namespace.url.value,
          'smartnote:$userId:subject:${row.id}',
        );
        await into(subjects).insertOnConflictUpdate(row.copyWith(id: id));
        await _rewriteNoteSubjects(row.id, id);
        await (delete(subjects)..where((t) => t.id.equals(row.id))).go();
      }
      return select(subjects).get();
    });
  }

  Future<void> applyRemoteSubjects(List<SubjectRow> incoming) {
    return transaction(() async {
      for (final row in incoming) {
        final current = await (select(
          subjects,
        )..where((table) => table.id.equals(row.id))).getSingleOrNull();
        if (current != null && !row.updatedAt.isAfter(current.updatedAt)) {
          continue;
        }
        await into(subjects).insertOnConflictUpdate(row);
      }
    });
  }

  Future<bool> updateSubject(String id, SubjectsCompanion row) async {
    return transaction(() async {
      final query = select(subjects)..where((table) => table.id.equals(id));
      final current = await query.getSingleOrNull();
      if (current == null || current.deletedAt != null) return false;
      final revision = nextLocalWriteTime(
        current.updatedAt,
        row.updatedAt.present ? row.updatedAt.value : DateTime.now(),
      );
      final affected =
          await (update(subjects)..where((table) => table.id.equals(id))).write(
            row.copyWith(updatedAt: Value(revision)),
          );
      return affected > 0;
    });
  }

  /// Xoá mềm môn học và chuyển các ghi chú của môn đó về "chưa phân loại"
  /// (giống `on delete set null` ở Supabase), trong cùng một giao dịch.
  Future<bool> softDeleteSubject(String id) {
    return transaction(() async {
      final now = DateTime.now();
      final deleted = await updateSubject(
        id,
        SubjectsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      if (deleted) {
        await _rewriteNoteSubjects(id, null);
      }
      return deleted;
    });
  }

  Future<void> _rewriteNoteSubjects(String source, String? target) async {
    final matches = await (select(
      notes,
    )..where((t) => t.subjectId.equals(source))).get();
    final now = DateTime.now();
    for (final row in matches) {
      await (update(notes)..where((t) => t.id.equals(row.id))).write(
        NotesCompanion(
          subjectId: Value(target),
          updatedAt: Value(nextLocalWriteTime(row.updatedAt, now)),
        ),
      );
    }
  }
}
