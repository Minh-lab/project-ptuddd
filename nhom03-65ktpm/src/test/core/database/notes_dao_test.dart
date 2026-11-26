import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_note/core/database/app_database.dart';
import 'package:smart_note/core/database/notes_dao.dart';

void main() {
  late AppDatabase database;
  late NotesDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = NotesDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  NotesCompanion newNote({
    required String id,
    String? userId = 'user-1',
    String title = '',
    String content = '',
    String kind = 'note',
    DateTime? updatedAt,
  }) {
    final now = updatedAt ?? DateTime(2026, 11, 21, 10);
    return NotesCompanion.insert(
      id: id,
      userId: Value(userId),
      title: Value(title),
      content: Value(content),
      kind: Value(kind),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  test('bảng notes tạo được và đọc lại đúng dữ liệu', () async {
    await dao.insertNote(
      newNote(id: 'n1', title: 'Ghi chú 1', content: 'Nội dung 1'),
    );

    final row = await dao.findById('n1', 'user-1');

    expect(row, isNotNull);
    expect(row!.title, 'Ghi chú 1');
    expect(row.content, 'Nội dung 1');
    expect(row.kind, 'note');
    expect(row.deletedAt, isNull);
  });

  test('getAll trả về ghi chú mới cập nhật trước', () async {
    await dao.insertNote(
      newNote(id: 'old', title: 'Cũ', updatedAt: DateTime(2026, 11, 20, 8)),
    );
    await dao.insertNote(
      newNote(id: 'new', title: 'Mới', updatedAt: DateTime(2026, 11, 21, 9)),
    );

    final rows = await dao.getAll('user-1');

    expect(rows.map((row) => row.id).toList(), <String>['new', 'old']);
  });

  test('updateNote đổi nội dung và updatedAt', () async {
    await dao.insertNote(newNote(id: 'n1', content: 'trước'));
    final later = DateTime(2026, 11, 21, 15);

    final updated = await dao.updateNote(
      'n1',
      'user-1',
      NotesCompanion(
        content: const Value<String>('sau'),
        updatedAt: Value<DateTime>(later),
      ),
    );

    final row = await dao.findById('n1', 'user-1');
    expect(updated, isTrue);
    expect(row!.content, 'sau');
    expect(row.updatedAt, later);
  });

  test(
    'softDeleteNote ẩn ghi chú khỏi danh sách nhưng còn trong bảng',
    () async {
      await dao.insertNote(newNote(id: 'n1'));

      await dao.softDeleteNote('n1', 'user-1');

      expect(await dao.getAll('user-1'), isEmpty);
      final row = await dao.findById('n1', 'user-1');
      expect(row, isNotNull);
      expect(row!.deletedAt, isNotNull);
    },
  );

  test('updateNote trả false khi id không tồn tại', () async {
    final updated = await dao.updateNote(
      'khong-ton-tai',
      'user-1',
      const NotesCompanion(content: Value<String>('x')),
    );

    expect(updated, isFalse);
  });

  test(
    'ghi chú chỉ đọc được bởi chủ; cache cũ vẫn được giữ nhưng bị ẩn',
    () async {
      await dao.insertNote(newNote(id: 'a', userId: 'user-a'));
      await dao.insertNote(newNote(id: 'b', userId: 'user-b'));
      await dao.insertNote(newNote(id: 'legacy', userId: null));

      expect((await dao.getAll('user-a')).map((row) => row.id), <String>['a']);
      expect((await dao.getAll('user-b')).map((row) => row.id), <String>['b']);
      expect(await dao.getAll('unknown-user'), isEmpty);

      final legacy = await (database.select(
        database.notes,
      )..where((row) => row.id.equals('legacy'))).getSingle();
      expect(legacy.userId, isNull);
    },
  );

  test('không cập nhật hoặc xoá được ghi chú thuộc tài khoản khác', () async {
    await dao.insertNote(newNote(id: 'a', userId: 'user-a'));

    expect(
      await dao.updateNote(
        'a',
        'user-b',
        const NotesCompanion(title: Value<String>('chiếm quyền')),
      ),
      isFalse,
    );
    expect(await dao.softDeleteNote('a', 'user-b'), isFalse);
    expect(await dao.findById('a', 'user-a'), isNotNull);
  });

  test('không đồng bộ đè ghi chú của tài khoản khác', () async {
    await dao.insertNote(newNote(id: 'a', userId: 'user-a'));

    await expectLater(
      dao.upsertSyncedNote(
        newNote(id: 'a', userId: 'user-b', title: 'không được ghi đè'),
      ),
      throwsStateError,
    );
    expect((await dao.findById('a', 'user-a'))!.title, '');
    expect(await dao.findById('a', 'user-b'), isNull);
  });

  test('migration giữ ghi chú cũ nhưng để trống UID chủ sở hữu', () async {
    await database.close();
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA user_version = 2');
          database.execute('''
            CREATE TABLE notes (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL DEFAULT '',
              content TEXT NOT NULL DEFAULT '',
              subject_id TEXT,
              tags TEXT NOT NULL DEFAULT '',
              kind TEXT NOT NULL DEFAULT 'note',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              deleted_at INTEGER
            )
          ''');
          database.execute('''
            CREATE TABLE quiz_scores (
              id TEXT NOT NULL PRIMARY KEY,
              note_id TEXT NOT NULL,
              note_title TEXT NOT NULL DEFAULT '',
              correct_answers INTEGER NOT NULL,
              total_questions INTEGER NOT NULL,
              completed_at INTEGER NOT NULL
            )
          ''');
          database.execute(
            "INSERT INTO notes (id, created_at, updated_at) "
            "VALUES ('legacy', 0, 0)",
          );
        },
      ),
    );
    dao = NotesDao(database);

    expect(await dao.getAll('user-a'), isEmpty);
    final legacy = await database
        .customSelect(
          'SELECT id, user_id FROM notes WHERE id = ?',
          variables: <Variable<Object>>[Variable.withString('legacy')],
        )
        .getSingle();
    expect(legacy.read<String>('id'), 'legacy');
    expect(legacy.readNullable<String>('user_id'), isNull);
  });
}
