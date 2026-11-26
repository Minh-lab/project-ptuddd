import 'package:drift/drift.dart';

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

  Future<bool> updateSubject(String id, SubjectsCompanion row) async {
    final affected = await (update(
      subjects,
    )..where((Subjects t) => t.id.equals(id))).write(row);
    return affected > 0;
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
        await (update(notes)..where((Notes t) => t.subjectId.equals(id))).write(
          NotesCompanion(
            subjectId: const Value<String?>(null),
            updatedAt: Value(now),
          ),
        );
      }
      return deleted;
    });
  }
}
