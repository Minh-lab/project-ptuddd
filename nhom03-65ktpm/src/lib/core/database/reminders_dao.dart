import 'package:drift/drift.dart';

import 'app_database.dart';
import 'tables.dart';

part 'reminders_dao.g.dart';

/// Truy cập bảng [Reminders] — chỉ tầng `data` được dùng DAO này.
@DriftAccessor(tables: [Reminders])
class RemindersDao extends DatabaseAccessor<AppDatabase>
    with _$RemindersDaoMixin {
  RemindersDao(super.db);

  /// Theo dõi mọi nhắc nhở, theo thứ tự tạo.
  Stream<List<ReminderRow>> watchAll() {
    final query = select(reminders)
      ..orderBy([(Reminders t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  Future<List<ReminderRow>> getAll() => select(reminders).get();

  Future<ReminderRow?> findById(String id) {
    return (select(
      reminders,
    )..where((Reminders t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Thêm mới hoặc ghi đè theo `id`.
  Future<void> upsertReminder(RemindersCompanion row) =>
      into(reminders).insertOnConflictUpdate(row);

  Future<bool> deleteReminder(String id) async {
    final affected = await (delete(
      reminders,
    )..where((Reminders t) => t.id.equals(id))).go();
    return affected > 0;
  }
}
