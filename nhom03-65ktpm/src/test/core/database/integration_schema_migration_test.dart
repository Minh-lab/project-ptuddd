import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';

void main() {
  for (final table in ['reminders', 'subjects']) {
    test(
      'schema 4 adds the other feature table and keeps existing $table data',
      () async {
        final database = AppDatabase(
          NativeDatabase.memory(
            setup: (sqlite) {
              sqlite.execute('CREATE TABLE $table (id TEXT PRIMARY KEY)');
              sqlite.execute(
                "INSERT INTO $table (id) VALUES ('already-local')",
              );
              sqlite.execute('PRAGMA user_version = 3');
            },
          ),
        );
        addTearDown(database.close);

        final tables = await database
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get();
        expect(
          tables.map((row) => row.read<String>('name')),
          containsAll(['reminders', 'subjects']),
        );

        final oldRow = await database
            .customSelect('SELECT id FROM $table')
            .getSingle();
        expect(oldRow.read<String>('id'), 'already-local');
      },
    );
  }
}
