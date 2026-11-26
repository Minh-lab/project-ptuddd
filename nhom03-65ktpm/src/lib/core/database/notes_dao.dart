import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'notes_dao.g.dart';

/// Truy cập bảng [Notes] — chỉ tầng `data` được dùng DAO này.
@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  /// Theo dõi toàn bộ ghi chú chưa bị xoá, mới cập nhật trước.
  Stream<List<NoteRow>> watchAll(String userId) {
    final query = select(notes)
      ..where((Notes t) => t.userId.equals(userId) & t.deletedAt.isNull())
      ..orderBy([(Notes t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }

  /// Lấy toàn bộ ghi chú chưa bị xoá (một lần).
  Future<List<NoteRow>> getAll(String userId) {
    final query = select(notes)
      ..where((Notes t) => t.userId.equals(userId) & t.deletedAt.isNull())
      ..orderBy([(Notes t) => OrderingTerm.desc(t.updatedAt)]);
    return query.get();
  }

  Future<NoteRow?> findById(String id, String userId) {
    return (select(
      notes,
    )..where((Notes t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<void> insertNote(NotesCompanion row) => into(notes).insert(row);

  Future<void> upsertSyncedNote(NotesCompanion row) async {
    if (!row.userId.present) {
      throw ArgumentError('Synced notes must have an owner UID.');
    }
    final userId = row.userId.value;
    if (userId == null) {
      throw ArgumentError('Synced notes must have an owner UID.');
    }

    await transaction(() async {
      final existing = await (select(
        notes,
      )..where((Notes t) => t.id.equals(row.id.value))).getSingleOrNull();
      if (existing?.userId != null && existing!.userId != userId) {
        throw StateError('Cannot transfer a cached note between users.');
      }
      await into(notes).insertOnConflictUpdate(row);
    });
  }

  Future<bool> updateNote(
    String id,
    String userId,
    NotesCompanion row,
  ) async {
    final affected = await (update(
      notes,
    )..where((Notes t) => t.id.equals(id) & t.userId.equals(userId))).write(row);
    return affected > 0;
  }

  /// Xoá mềm để không mất dữ liệu khi đồng bộ với Supabase.
  Future<bool> softDeleteNote(String id, String userId) {
    return updateNote(
      id,
      userId,
      NotesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
