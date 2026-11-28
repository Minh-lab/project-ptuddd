import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Cơ sở dữ liệu cục bộ (SQLite qua Drift) — cache offline của ứng dụng.
///
/// Nguồn dữ liệu chính là Supabase; Drift giữ bản sao để dùng khi mất mạng.
@DriftDatabase(tables: [Notes, QuizScores, Reminders, Subjects])
class AppDatabase extends _$AppDatabase {
  /// [executor] chỉ dùng cho test (ví dụ `NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor, String databaseName = 'smart_note'])
    : super(
        executor ??
            driftDatabase(
              name: databaseName,
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(quizScores);
      }
      if (from < 4) {
        final rows = await customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ).get();
        final existing = rows.map((row) => row.read<String>('name')).toSet();
        if (!existing.contains(reminders.actualTableName)) {
          await m.createTable(reminders);
        }
        if (!existing.contains(subjects.actualTableName)) {
          await m.createTable(subjects);
        }
      }
    },
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
